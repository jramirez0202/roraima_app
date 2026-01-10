import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["captureInput", "captureBtn", "previewContainer", "photoCount",
                    "uploadBtn", "statusIndicator"]

  static values = {
    packageId: Number,
    uploadUrl: String,
    statusUrl: String
  }

  async connect() {
    this.maxPhotos = 4
    this.photos = []
    this.uploadedCount = 0 // Contador de fotos ya subidas
    this.dbName = 'roraima_photos'

    // Esperar a que IndexedDB se inicialice antes de cargar fotos
    await this.initIndexedDB()
    await this.loadPendingPhotos()

    this.setupOnlineListener()
  }

  // Inicializar IndexedDB
  async initIndexedDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, 1)

      request.onerror = () => reject(request.error)
      request.onsuccess = () => {
        this.db = request.result
        resolve(this.db)
      }

      request.onupgradeneeded = (event) => {
        const db = event.target.result
        if (!db.objectStoreNames.contains('photos')) {
          db.createObjectStore('photos', { keyPath: 'id', autoIncrement: true })
        }
      }
    })
  }

  // Capturar foto
  async capturePhoto(event) {
    const file = event.target.files[0]
    if (!file) return

    if (this.photos.length >= this.maxPhotos) {
      alert(`Máximo ${this.maxPhotos} fotos`)
      return
    }

    // Guardar en IndexedDB (persistencia offline)
    await this.savePhotoToIndexedDB(file)

    // Agregar a array local
    this.photos.push(file)

    // Crear preview
    this.addPreview(file, this.photos.length - 1)

    // Actualizar UI
    this.updateUI()

    // NO subir automáticamente - esperar a que usuario presione "Subir Fotos"
    event.target.value = ''
  }

  // Guardar en IndexedDB
  async savePhotoToIndexedDB(file) {
    // Obtener arrayBuffer ANTES de abrir la transacción
    const blob = await file.arrayBuffer()

    // Ahora abrir la transacción y guardar
    const transaction = this.db.transaction(['photos'], 'readwrite')
    const store = transaction.objectStore('photos')

    const photoData = {
      packageId: this.packageIdValue,
      blob: blob,
      filename: file.name,
      type: file.type,
      timestamp: new Date().toISOString()
    }

    return new Promise((resolve, reject) => {
      const request = store.add(photoData)
      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  // Cargar fotos pendientes
  async loadPendingPhotos() {
    if (!this.db) {
      console.warn('IndexedDB not initialized yet')
      return
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['photos'], 'readonly')
      const store = transaction.objectStore('photos')
      const request = store.getAll()

      request.onsuccess = () => {
        const storedPhotos = request.result.filter(p => p.packageId === this.packageIdValue)
        storedPhotos.forEach((photoData, index) => {
          const file = new File([photoData.blob], photoData.filename, { type: photoData.type })
          this.photos.push(file)
          this.addPreview(file, index)
        })
        this.updateUI()
        resolve()
      }

      request.onerror = () => reject(request.error)
    })
  }

  // Subir fotos pendientes
  async uploadPendingPhotos() {
    if (this.photos.length === 0) return

    this.uploadBtnTarget.disabled = true
    this.uploadBtnTarget.textContent = '⏳ Subiendo...'

    const formData = new FormData()
    this.photos.forEach((photo, index) => {
      formData.append('photos[]', photo)
    })

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (data.success) {
        // Guardar nombres de archivos antes de limpiar
        const uploadedFileNames = this.photos.map(photo => photo.name)
        this.uploadedCount = uploadedFileNames.length

        this.clearIndexedDB()
        this.photos = []
        this.previewContainerTarget.innerHTML = ''

        // Mostrar lista de archivos subidos en lugar de previews
        this.showUploadedFilesList(uploadedFileNames)

        this.updateUI()
        this.showSuccess('✅ Fotos subidas correctamente a S3')

        // Marcar fotos como subidas para habilitar botón "Actualizar Estado"
        if (typeof window.markPhotosAsUploaded === 'function') {
          window.markPhotosAsUploaded()
        }

        // Polling para verificar confirmación
        this.startPolling()
      } else {
        this.showError('❌ Error al subir fotos: ' + data.errors.join(', '))
      }
    } catch (error) {
      this.showError('❌ Error de conexión')
    } finally {
      this.uploadBtnTarget.disabled = false
      this.uploadBtnTarget.textContent = '📤 Subir Fotos'
    }
  }

  // UI helpers
  addPreview(file, index) {
    const url = URL.createObjectURL(file)
    const div = document.createElement('div')
    div.className = 'relative bg-gray-100 rounded-lg border-2 border-green-500 cursor-pointer hover:border-green-600 transition'
    div.setAttribute('data-photo-index', index)

    div.innerHTML = `
      <img src="${url}" class="w-full h-40 sm:h-32 object-cover rounded-lg" data-url="${url}" data-index="${index}">
      <button type="button" class="absolute top-2 right-2 bg-red-600 text-white rounded-full w-8 h-8 hover:bg-red-700 z-10">×</button>
      <div class="absolute bottom-0 left-0 right-0 bg-green-600 text-white text-center py-1 text-sm">📷 Foto ${index + 1}</div>
      <div class="absolute top-2 left-2 bg-blue-600 text-white rounded-full w-8 h-8 flex items-center justify-center">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"/>
        </svg>
      </div>
    `

    // Click en imagen para ver en grande
    const img = div.querySelector('img')
    img.onclick = (e) => {
      e.stopPropagation()
      this.openPhotoModal(url, index + 1, file.name)
    }

    // Botón eliminar
    div.querySelector('button').onclick = (e) => {
      e.stopPropagation()
      this.removePhoto(index)
    }

    this.previewContainerTarget.appendChild(div)
  }

  removePhoto(index) {
    this.photos.splice(index, 1)
    this.previewContainerTarget.innerHTML = ''
    this.photos.forEach((photo, i) => this.addPreview(photo, i))
    this.updateUI()
  }

  updateUI() {
    const pendingCount = this.photos.length

    if (this.uploadedCount > 0) {
      // Ya hay fotos subidas - deshabilitar captura
      this.photoCountTarget.textContent = `${this.uploadedCount} ${this.uploadedCount === 1 ? 'foto subida' : 'fotos subidas'} ✅`
      this.uploadBtnTarget.disabled = true
      this.uploadBtnTarget.textContent = '✅ Fotos Subidas'
      this.captureBtnTarget.disabled = true
      this.captureInputTarget.disabled = true
    } else {
      // Modo normal (tomando fotos)
      this.photoCountTarget.textContent = `${pendingCount}/4 fotos`
      this.uploadBtnTarget.disabled = pendingCount === 0
      this.uploadBtnTarget.textContent = '📤 Subir Fotos a S3'
      this.captureBtnTarget.disabled = false
      this.captureInputTarget.disabled = false
    }
  }

  setupOnlineListener() {
    window.addEventListener('online', () => {
      this.statusIndicatorTarget.innerHTML = '<span class="text-green-600">🟢 Conectado</span>'
      this.uploadPendingPhotos()
    })

    window.addEventListener('offline', () => {
      this.statusIndicatorTarget.innerHTML = '<span class="text-orange-600">🟠 Sin conexión</span>'
    })
  }

  async clearIndexedDB() {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['photos'], 'readwrite')
      const store = transaction.objectStore('photos')
      const request = store.getAll()

      request.onsuccess = () => {
        const storedPhotos = request.result.filter(p => p.packageId === this.packageIdValue)

        if (storedPhotos.length === 0) {
          resolve()
          return
        }

        const deleteTransaction = this.db.transaction(['photos'], 'readwrite')
        const deleteStore = deleteTransaction.objectStore('photos')

        storedPhotos.forEach(photo => {
          deleteStore.delete(photo.id)
        })

        deleteTransaction.oncomplete = () => resolve()
        deleteTransaction.onerror = () => reject(deleteTransaction.error)
      }

      request.onerror = () => reject(request.error)
    })
  }

  startPolling() {
    // Poll cada 5 segundos para verificar si S3 confirmó las fotos
    const pollInterval = setInterval(async () => {
      try {
        const response = await fetch(this.statusUrlValue)
        const data = await response.json()

        if (data.photos_confirmed) {
          clearInterval(pollInterval)
          this.showSuccess('✅ Entrega confirmada con evidencia fotográfica')
          setTimeout(() => {
            window.location.href = '/drivers'
          }, 2000)
        }
      } catch (error) {
        console.error('Error polling status:', error)
      }
    }, 5000)

    // Detener después de 2 minutos
    setTimeout(() => clearInterval(pollInterval), 120000)
  }

  openPhotoModal(imageUrl, photoNumber, fileName) {
    const modal = document.getElementById('photo-upload-modal')
    const img = document.getElementById('photo-upload-modal-img')
    const info = document.getElementById('photo-upload-modal-info')

    if (modal && img && info) {
      img.src = imageUrl
      info.textContent = `📷 Foto ${photoNumber} - ${fileName}`
      modal.classList.remove('hidden')
      document.body.style.overflow = 'hidden'
    }
  }

  closePhotoModal() {
    const modal = document.getElementById('photo-upload-modal')
    if (modal) {
      modal.classList.add('hidden')
      document.body.style.overflow = 'auto'
    }
  }

  showUploadedFilesList(fileNames) {
    const listHtml = `
      <div class="bg-green-50 border-2 border-green-200 rounded-lg p-4">
        <h3 class="text-sm font-semibold text-green-800 mb-2">
          ✅ ${fileNames.length} ${fileNames.length === 1 ? 'foto subida' : 'fotos subidas'} correctamente
        </h3>
        <ul class="space-y-1">
          ${fileNames.map((name, index) => `
            <li class="flex items-center text-xs text-green-700">
              <svg class="w-4 h-4 mr-2 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
              </svg>
              <span class="truncate">${index + 1}. ${name}</span>
            </li>
          `).join('')}
        </ul>
        <p class="mt-3 text-xs text-green-600 italic">
          📋 Las fotos aparecerán en la sección "Fotos de Evidencia de Entrega" después de actualizar el estado.
        </p>
      </div>
    `
    this.previewContainerTarget.innerHTML = listHtml
  }

  showSuccess(message) {
    alert(message)
  }

  showError(message) {
    alert(message)
  }
}
