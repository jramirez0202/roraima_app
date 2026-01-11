// Scanner controller para manejo de escaneo QR/códigos de barras
// Soporta dos modos:
// 1. Zebra TC15 / Scanner USB (modo HID keyboard)
// 2. Cámara HTML5 (para móviles y tablets)
import { Controller } from "@hotwired/stimulus"
// Html5Qrcode se carga desde CDN (global window.Html5Qrcode)

export default class extends Controller {
  static targets = [
    "input",
    "inputContainer",
    "manualProcessBtn",
    "feedback",
    "feedbackContent",
    "recentList",
    "sessionCount",
    "statusIndicator",
    "statusText",
    "spinner",
    "cameraBtn",
    "cameraBtnText",
    "cameraContainer",
    "modeButton",
    "modeDescription",
    "customerSelector",
    "customerSelect"
  ]

  static values = {
    processUrl: { type: String, default: "/admin/scanner/process" },
    createUrl: { type: String, default: "/admin/scanner/create_package" },
    resetUrl: { type: String, default: "/admin/scanner/reset_session" }
  }

  connect() {
    this.recentScans = []
    this.scannedCodes = new Set() // Track códigos ya escaneados
    this.isProcessing = false
    this.lastScanTime = 0
    this.lastScanCode = null // Último código escaneado
    this.html5QrCode = null
    this.isCameraActive = false
    this.currentMode = 'warehouse' // Default: ingresar a bodega

    // Asegurar que el input esté enfocado
    this.focusInput()

    // Re-enfocar cuando el usuario hace click en cualquier parte
    // (útil para mantener el input activo con escáneres de barras)
    this.documentClickHandler = this.handleDocumentClick.bind(this)
    document.addEventListener('click', this.documentClickHandler)
  }

  disconnect() {
    document.removeEventListener('click', this.documentClickHandler)

    // Detener cámara si está activa
    if (this.isCameraActive && this.html5QrCode) {
      this.stopCamera()
    }
  }

  // === MODE MANAGEMENT ===

  setMode(event) {
    const newMode = event.currentTarget.dataset.mode

    // Update current mode
    this.currentMode = newMode

    // Update button styles
    this.modeButtonTargets.forEach(btn => {
      const btnMode = btn.dataset.mode
      if (btnMode === newMode) {
        // Active state
        btn.classList.remove('border-gray-300', 'bg-white', 'text-gray-700')
        btn.classList.add('border-indigo-600', 'bg-indigo-600', 'text-white')
      } else {
        // Inactive state
        btn.classList.remove('border-indigo-600', 'bg-indigo-600', 'text-white')
        btn.classList.add('border-gray-300', 'bg-white', 'text-gray-700')
      }
    })

    // Update description
    const descriptions = {
      warehouse: 'Escanea para ingresar paquetes a bodega (cambia estado a "Bodega")',
      create: '1. Selecciona cliente → 2. Activa cámara → 3. Escanea código'
    }
    this.modeDescriptionTarget.textContent = descriptions[newMode] || ''

    // Show/hide elements based on mode
    if (newMode === 'create') {
      // Modo CREATE: Solo cámara, sin input manual
      if (this.hasCustomerSelectorTarget) {
        this.customerSelectorTarget.classList.remove('hidden')
      }
      if (this.hasInputContainerTarget) {
        this.inputContainerTarget.classList.add('hidden')
      }
      if (this.hasManualProcessBtnTarget) {
        this.manualProcessBtnTarget.classList.add('hidden')
      }
    } else {
      // Modo WAREHOUSE: Input manual visible
      if (this.hasCustomerSelectorTarget) {
        this.customerSelectorTarget.classList.add('hidden')
      }
      if (this.hasInputContainerTarget) {
        this.inputContainerTarget.classList.remove('hidden')
      }
      if (this.hasManualProcessBtnTarget) {
        this.manualProcessBtnTarget.classList.remove('hidden')
      }
      // Focus input solo en modo warehouse
      this.focusInput()
    }

    // Clear scanned codes set when changing modes
    this.scannedCodes.clear()
  }

  // === EVENT HANDLERS ===

  handleDocumentClick(event) {
    // No re-enfocar si se hace click en:
    // - Botones o links
    // - Buscador de clientes (autocomplete)
    // - Input de scanner en modo create (para permitir usar el buscador)
    if (!event.target.closest('button, a, [data-controller="autocomplete"]')) {
      // En modo create, no forzar focus (permite usar buscador de clientes)
      if (this.currentMode !== 'create') {
        this.focusInput()
      }
    }
  }

  processScan(event) {
    event.preventDefault()

    const input = this.inputTarget.value.trim()

    if (!input) {
      this.showError('Campo vacío, escanea un código')
      return
    }

    // Procesar el escaneo (las validaciones de duplicados están en performScan)
    this.performScan(input)
  }

  manualProcess(event) {
    event.preventDefault()
    this.processScan({ preventDefault: () => {} })
  }

  handleFocus(event) {
    // No longer auto-add PKG- prefix - allow typing any format
    // This enables MLB (20000...) and FLB (10-digit) codes
  }

  handleInput(event) {
    // No longer force PKG- prefix - allow all provider formats
    // Scanner now accepts PKG, MLB, and FLB tracking codes
  }

  async resetSession(event) {
    event.preventDefault()

    if (!confirm('¿Reiniciar el contador de escaneos de esta sesión?')) {
      return
    }

    try {
      const response = await this.fetchJSON(this.resetUrlValue, {
        method: 'POST'
      })

      if (response.success) {
        this.sessionCountTarget.textContent = '0'
        this.recentScans = []
        this.scannedCodes.clear() // Limpiar códigos escaneados
        this.lastScanCode = null // Reset último código
        this.renderRecentScans()
        this.showSuccess('Sesión reiniciada')
      }
    } catch (error) {
      this.showError('Error al reiniciar sesión')
    }
  }

  // === CORE SCAN LOGIC ===

  async performScan(trackingInput) {
    if (this.isProcessing) {
      return
    }

    // === VALIDACIÓN DE CLIENTE EN MODO CREATE ===
    if (this.currentMode === 'create') {
      const customerId = this.hasCustomerSelectTarget ? this.customerSelectTarget.value : null
      if (!customerId) {
        this.showError('Debes seleccionar un cliente antes de escanear')
        return
      }
    }

    // === VALIDACIÓN DE DUPLICADOS (aplica a todos los modos de escaneo) ===
    const now = Date.now()

    // 1. Prevenir escaneos del mismo código en < 2 segundos
    if (trackingInput === this.lastScanCode && (now - this.lastScanTime < 2000)) {
      return
    }

    // 2. Extraer tracking code y verificar si ya está en sesión
    const trackingCode = this.extractTrackingCode(trackingInput)
    if (trackingCode && this.scannedCodes.has(trackingCode)) {
      this.showDuplicateError(trackingCode)
      return
    }

    // 3. Debounce general
    if (now - this.lastScanTime < 500) {
      return
    }

    this.lastScanTime = now
    this.lastScanCode = trackingInput

    this.isProcessing = true
    this.setLoading(true)

    try {
      // Decide qué endpoint usar según el modo
      const url = this.currentMode === 'create' ? this.createUrlValue : this.processUrlValue

      // Preparar body del request
      const requestBody = { tracking_input: trackingInput }

      // Agregar customer_id si estamos en modo "create"
      if (this.currentMode === 'create' && this.hasCustomerSelectTarget) {
        requestBody.customer_id = this.customerSelectTarget.value
      }

      const response = await this.fetchJSON(url, {
        method: 'POST',
        body: JSON.stringify(requestBody)
      })

      if (response.success) {
        // Agregar código al Set de escaneados (usar tracking_code normalizado del servidor)
        if (!response.warning && response.package && response.package.tracking_code) {
          this.scannedCodes.add(response.package.tracking_code)
        }

        if (response.warning) {
          this.showWarning(response.message, response.package)
        } else {
          this.showSuccess(response.message, response.package)
          this.playSuccessSound()
        }

        // Actualizar contador de sesión
        if (response.session_count) {
          this.sessionCountTarget.textContent = response.session_count
        }

        // Agregar a lista de escaneos recientes
        this.addRecentScan(response.package, response.warning ? 'warning' : 'success')

      } else {
        this.showError(response.error)
        this.playErrorSound()
      }

    } catch (error) {
      console.error('Error en escaneo:', error)
      this.showError(error.message || 'Error de conexión')
      this.playErrorSound()
    } finally {
      this.isProcessing = false
      this.setLoading(false)
      // Solo limpiar input si viene de escaneo manual/keyboard (no cámara)
      if (this.inputTarget && this.inputTarget.value === trackingInput) {
        this.clearAndFocus()
      }
    }
  }

  // === UI STATE MANAGEMENT ===

  setLoading(loading) {
    if (loading) {
      this.inputTarget.disabled = true
      this.spinnerTarget.classList.remove('hidden')
      this.statusIndicatorTarget.classList.remove('bg-green-500')
      this.statusIndicatorTarget.classList.add('bg-blue-500')
      this.statusTextTarget.textContent = 'Procesando...'
    } else {
      this.inputTarget.disabled = false
      this.spinnerTarget.classList.add('hidden')
      this.statusIndicatorTarget.classList.remove('bg-blue-500')
      this.statusIndicatorTarget.classList.add('bg-green-500')
      this.statusTextTarget.textContent = 'Listo para escanear'
    }
  }

  clearAndFocus() {
    this.inputTarget.value = 'PKG-'
    this.focusInput()
  }

  focusInput() {
    setTimeout(() => {
      this.inputTarget.focus()
      // Posicionar cursor después de "PKG-" en vez de seleccionar todo
      const prefix = 'PKG-'
      if (this.inputTarget.value.startsWith(prefix)) {
        this.inputTarget.setSelectionRange(prefix.length, this.inputTarget.value.length)
      } else {
        this.inputTarget.select()
      }
    }, 100)
  }

  // === FEEDBACK RENDERING ===

  showSuccess(message, packageData) {
    this.feedbackTarget.classList.remove('hidden')
    this.feedbackContentTarget.className = 'rounded-lg p-4 bg-green-50 border-l-4 border-green-500'
    this.feedbackContentTarget.innerHTML = this.successHTML(message, packageData)

    // Auto-ocultar después de 3 segundos
    setTimeout(() => {
      this.feedbackTarget.classList.add('hidden')
    }, 3000)
  }

  showWarning(message, packageData) {
    this.feedbackTarget.classList.remove('hidden')
    this.feedbackContentTarget.className = 'rounded-lg p-4 bg-yellow-50 border-l-4 border-yellow-500'
    this.feedbackContentTarget.innerHTML = this.warningHTML(message, packageData)

    setTimeout(() => {
      this.feedbackTarget.classList.add('hidden')
    }, 3000)
  }

  showError(message) {
    this.feedbackTarget.classList.remove('hidden')
    this.feedbackContentTarget.className = 'rounded-lg p-4 bg-red-50 border-l-4 border-red-500'
    this.feedbackContentTarget.innerHTML = this.errorHTML(message)

    setTimeout(() => {
      this.feedbackTarget.classList.add('hidden')
    }, 4000)
  }

  showDuplicateError(trackingCode) {
    this.feedbackTarget.classList.remove('hidden')
    this.feedbackContentTarget.className = 'rounded-lg p-4 bg-red-50 border-l-4 border-red-500'
    this.feedbackContentTarget.innerHTML = this.duplicateErrorHTML(trackingCode)

    // Sonido de error
    this.playErrorSound()

    setTimeout(() => {
      this.feedbackTarget.classList.add('hidden')
    }, 3000)
  }

  successHTML(message, pkg) {
    if (!pkg) return `<p class="text-green-800 font-medium">${message}</p>`

    return `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-green-500" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
          </svg>
        </div>
        <div class="ml-3 flex-1">
          <p class="text-sm font-medium text-green-800">${message}</p>
          <div class="mt-2 text-sm text-green-700">
            <p><strong>${pkg.tracking_code}</strong></p>
            <p>${pkg.customer_name} - ${pkg.commune}</p>
          </div>
        </div>
      </div>
    `
  }

  warningHTML(message, pkg) {
    return `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-yellow-800">${message}</p>
          ${pkg ? `<p class="mt-1 text-sm text-yellow-700">${pkg.tracking_code}</p>` : ''}
        </div>
      </div>
    `
  }

  errorHTML(message) {
    return `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-red-500" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-red-800">${message}</p>
        </div>
      </div>
    `
  }

  duplicateErrorHTML(trackingCode) {
    return `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-red-500" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-red-800">❌ Código duplicado</p>
          <p class="mt-1 text-sm text-red-700">${trackingCode} ya fue escaneado en esta sesión</p>
        </div>
      </div>
    `
  }

  // === RECENT SCANS LIST ===

  addRecentScan(packageData, type) {
    this.recentScans.unshift({
      ...packageData,
      type: type,
      timestamp: new Date().toLocaleTimeString('es-CL')
    })

    // Mantener solo los últimos 20
    if (this.recentScans.length > 20) {
      this.recentScans = this.recentScans.slice(0, 20)
    }

    this.renderRecentScans()
  }

  renderRecentScans() {
    if (this.recentScans.length === 0) {
      this.recentListTarget.innerHTML = `
        <div class="text-center py-8 text-gray-400">
          <svg class="mx-auto h-12 w-12 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
          </svg>
          <p>No hay escaneos en esta sesión</p>
        </div>
      `
      return
    }

    const html = this.recentScans.map(scan => this.scanItemHTML(scan)).join('')
    this.recentListTarget.innerHTML = html
  }

  scanItemHTML(scan) {
    const bgColor = scan.type === 'success' ? 'bg-green-50' : 'bg-yellow-50'
    const borderColor = scan.type === 'success' ? 'border-green-200' : 'border-yellow-200'
    const iconColor = scan.type === 'success' ? 'text-green-600' : 'text-yellow-600'
    const icon = scan.type === 'success' ? '✓' : '⚠'

    return `
      <div class="flex items-center justify-between p-3 ${bgColor} border ${borderColor} rounded-lg">
        <div class="flex items-center space-x-3 flex-1 min-w-0">
          <span class="text-lg ${iconColor}">${icon}</span>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">${scan.tracking_code}</p>
            <p class="text-xs text-gray-500 truncate">${scan.customer_name} - ${scan.commune}</p>
          </div>
        </div>
        <div class="ml-4 flex-shrink-0">
          <span class="text-xs text-gray-500">${scan.timestamp}</span>
        </div>
      </div>
    `
  }

  // === AUDIO FEEDBACK ===

  playSuccessSound() {
    // Beep de éxito (pitch alto)
    try {
      const audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const oscillator = audioContext.createOscillator()
      const gainNode = audioContext.createGain()

      oscillator.connect(gainNode)
      gainNode.connect(audioContext.destination)

      oscillator.frequency.value = 800 // Tono de éxito (pitch alto)
      oscillator.type = 'sine'

      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime)
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1)

      oscillator.start(audioContext.currentTime)
      oscillator.stop(audioContext.currentTime + 0.1)
    } catch (error) {
      // Audio no disponible o bloqueado
    }
  }

  playErrorSound() {
    // Beep de error (pitch bajo)
    try {
      const audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const oscillator = audioContext.createOscillator()
      const gainNode = audioContext.createGain()

      oscillator.connect(gainNode)
      gainNode.connect(audioContext.destination)

      oscillator.frequency.value = 400 // Tono de error (pitch bajo)
      oscillator.type = 'sine'

      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime)
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.15)

      oscillator.start(audioContext.currentTime)
      oscillator.stop(audioContext.currentTime + 0.15)
    } catch (error) {
      // Audio no disponible
    }
  }

  // === CAMERA QR SCANNER ===

  async toggleCamera() {
    if (this.isCameraActive) {
      await this.stopCamera()
    } else {
      await this.startCamera()
    }
  }

  async startCamera() {
    try {
      // === VALIDACIÓN EN MODO CREATE ===
      if (this.currentMode === 'create') {
        const customerId = this.hasCustomerSelectTarget ? this.customerSelectTarget.value : null
        if (!customerId) {
          this.showError('Primero debes seleccionar un cliente')
          return
        }
      }

      // Verificar que la librería esté cargada
      const Html5Qrcode = window.Html5Qrcode

      if (!Html5Qrcode) {
        throw new Error('Html5Qrcode no está cargado. Verifica la conexión a internet.')
      }

      // Ocultar input manual y mostrar contenedor de cámara
      if (this.hasInputContainerTarget) {
        this.inputContainerTarget.classList.add('hidden')
      }
      this.cameraContainerTarget.classList.remove('hidden')

      // Inicializar lector QR
      this.html5QrCode = new Html5Qrcode("qr-reader")

      // Configuración de la cámara
      const config = {
        fps: 10,
        qrbox: { width: 250, height: 250 },
        aspectRatio: 1.0
      }

      // Callback cuando se detecta un QR
      const onScanSuccess = (decodedText, decodedResult) => {
        // === MODO CONTINUO: NO cerramos la cámara ===
        // La cámara permanece activa para el siguiente escaneo
        // Simplemente procesamos el código y dejamos la cámara lista
        this.performScan(decodedText)
      }

      // Callback de error (opcional, no hacer nada si no hay QR)
      const onScanError = (errorMessage) => {
        // Ignorar errores de "No QR code found" que son normales
      }

      // Intentar usar cámara trasera si está disponible (mejor para escanear)
      const cameras = await Html5Qrcode.getCameras()

      let cameraId = { facingMode: "environment" } // Cámara trasera por defecto

      // Si hay múltiples cámaras, intentar encontrar la trasera
      if (cameras && cameras.length > 1) {
        const rearCamera = cameras.find(cam =>
          cam.label.toLowerCase().includes('back') ||
          cam.label.toLowerCase().includes('rear') ||
          cam.label.toLowerCase().includes('trasera')
        )
        if (rearCamera) {
          cameraId = rearCamera.id
        }
      }

      // Iniciar escaneo
      await this.html5QrCode.start(
        cameraId,
        config,
        onScanSuccess,
        onScanError
      )

      this.isCameraActive = true

      // Actualizar botón
      this.cameraBtnTextTarget.textContent = 'Detener Cámara'
      this.cameraBtnTarget.classList.remove('bg-green-600', 'hover:bg-green-700')
      this.cameraBtnTarget.classList.add('bg-red-600', 'hover:bg-red-700')

    } catch (error) {
      // Error crítico: mantener para debugging de problemas de cámara
      console.error('Error al iniciar cámara:', error)

      let errorMsg = 'Error al acceder a la cámara'

      if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
        errorMsg = 'Permiso de cámara denegado. Por favor, permite el acceso a la cámara.'
      } else if (error.name === 'NotFoundError' || error.name === 'DevicesNotFoundError') {
        errorMsg = 'No se encontró ninguna cámara en este dispositivo.'
      } else if (error.name === 'NotReadableError' || error.name === 'TrackStartError') {
        errorMsg = 'La cámara está siendo usada por otra aplicación.'
      } else if (error.name === 'NotSupportedError' || error.message?.includes('https') || error.message?.includes('secure')) {
        errorMsg = 'HTTPS requerido. El navegador requiere HTTPS para acceder a la cámara. Usa "localhost" o activa permisos especiales en Chrome.'
      } else if (error.message) {
        errorMsg = error.message
      }

      this.showError(errorMsg)

      // Restaurar UI (solo en modo warehouse mostrar input)
      if (this.currentMode === 'warehouse' && this.hasInputContainerTarget) {
        this.inputContainerTarget.classList.remove('hidden')
      }
      this.cameraContainerTarget.classList.add('hidden')
    }
  }

  async stopCamera() {
    if (this.html5QrCode && this.isCameraActive) {
      try {
        await this.html5QrCode.stop()
      } catch (error) {
        console.error('Error al detener cámara:', error)
      }

      this.html5QrCode.clear()
      this.html5QrCode = null
      this.isCameraActive = false

      // Restaurar UI (solo en modo warehouse mostrar input)
      if (this.currentMode === 'warehouse' && this.hasInputContainerTarget) {
        this.inputContainerTarget.classList.remove('hidden')
      }
      this.cameraContainerTarget.classList.add('hidden')

      // Restaurar botón
      this.cameraBtnTextTarget.textContent = 'Activar Cámara QR'
      this.cameraBtnTarget.classList.remove('bg-red-600', 'hover:bg-red-700')
      this.cameraBtnTarget.classList.add('bg-green-600', 'hover:bg-green-700')

      // Re-enfocar input solo en modo warehouse
      if (this.currentMode === 'warehouse') {
        this.focusInput()
      }
    }
  }

  // === TRACKING CODE EXTRACTION ===

  extractTrackingCode(input) {
    if (!input) return null

    const cleaned = input.trim()

    // Provider patterns (same as Ruby)
    const patterns = {
      'PKG': /^PKG-\d{14}$/,     // PKG- + 14 digits (Rutiservice)
      'MLB': /^4622\d{7}$/,      // 4622 + 7 digits (Mercado Libre)
      'FLB': /^\d{10}$/          // 10 digits (Falabella)
    }

    // Caso 1: Tracking code plano - detectar provider
    for (const [provider, pattern] of Object.entries(patterns)) {
      if (cleaned.match(pattern)) {
        return cleaned
      }
    }

    // Caso 2: JSON del QR code
    if (cleaned.startsWith('{') || cleaned.startsWith('[')) {
      try {
        const jsonData = JSON.parse(cleaned)
        const data = Array.isArray(jsonData) ? jsonData[0] : jsonData
        // Buscar en múltiples claves posibles: "tracking", "id" (Mercado Libre usa "id")
        const tracking = data.tracking || data['tracking'] || data.id || data['id']

        if (tracking) {
          for (const [provider, pattern] of Object.entries(patterns)) {
            if (tracking.match(pattern)) {
              return tracking
            }
          }
        }
      } catch (e) {
        // Fall through
      }
    }

    // Caso 3: Buscar cualquier patrón válido en el string
    for (const [provider, pattern] of Object.entries(patterns)) {
      const match = cleaned.match(pattern)
      if (match) return match[0]
    }

    return null
  }

  // === HELPERS ===

  async fetchJSON(url, options = {}) {
    const csrfToken = document.querySelector('[name="csrf-token"]')?.content

    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken,
        ...options.headers
      }
    })

    if (!response.ok) {
      const data = await response.json()
      throw new Error(data.error || `HTTP ${response.status}`)
    }

    return response.json()
  }
}
