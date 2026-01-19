import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import imageCompression from "browser-image-compression"
import { openDB } from "idb"

/**
 * Base controller for photo capture and upload
 *
 * Características:
 * - Compresión automática paralela (5-8MB → <1MB) usando Web Workers
 * - Persistencia offline (IndexedDB)
 * - Direct Upload a S3
 * - 1-4 fotos requeridas
 * - Reintentos automáticos
 *
 * Extendido por:
 * - delivery_photos_controller.js
 * - reschedule_photos_controller.js
 * - cancelled_photos_controller.js
 */
export default class extends Controller {
  static targets = ["input", "preview", "count", "submit", "status"]
  static values = {
    packageId: Number,
    directUploadUrl: String,
    storeName: String,      // 'delivery-photos' | 'reschedule-photos' | 'cancelled-photos'
    inputName: String,      // Form input name for hidden fields
    modalId: String,        // Unique modal ID (e.g., 'delivery-photo-modal')
    consolePrefix: String   // Console log prefix (e.g., '📸', '📅', '❌')
  }

  async connect() {
    console.log(`${this.consolePrefixValue} Photo controller CONNECTING (store: ${this.storeNameValue})...`)

    this.MIN_PHOTOS = 1
    this.REQUIRED_FOR_UPLOAD = 1  // Mínimo para activar botón de subir
    this.MAX_PHOTOS = 4
    this.MAX_SIZE_MB = 0.8
    this.MAX_DIMENSION = 1600
    this.photos = []

    try {
      // Inicializar IndexedDB
      this.db = await this.initDB()
      console.log(`${this.consolePrefixValue} IndexedDB initialized`)

      // Cargar fotos pendientes
      await this.loadPendingPhotos()
      console.log(`${this.consolePrefixValue} Pending photos loaded`)

      // Listener de conexión
      window.addEventListener('online', () => this.onOnline())

      console.log(`${this.consolePrefixValue} Photo controller CONNECTED successfully`)
    } catch (error) {
      console.error(`${this.consolePrefixValue} Error connecting photo controller:`, error)
    }
  }

  // Inicializar IndexedDB
  async initDB() {
    return await openDB('roraima-delivery', 2, {
      upgrade(db) {
        // Crear stores para todos los tipos de fotos
        const storeNames = ['delivery-photos', 'reschedule-photos', 'cancelled-photos']

        storeNames.forEach(storeName => {
          if (!db.objectStoreNames.contains(storeName)) {
            const store = db.createObjectStore(storeName, { keyPath: 'id', autoIncrement: true })
            store.createIndex('packageId', 'packageId')
            store.createIndex('uploadStatus', 'uploadStatus')
          }
        })
      }
    })
  }

  // Capturar foto desde input - PARALLEL COMPRESSION (4x faster)
  async capturePhoto(event) {
    console.log(`${this.consolePrefixValue} capturePhoto called`)
    const files = Array.from(event.target.files)
    console.log(`${this.consolePrefixValue} Files selected:`, files.length)

    if (files.length === 0) {
      console.log(`${this.consolePrefixValue} No files selected`)
      return
    }

    if (this.photos.length + files.length > this.MAX_PHOTOS) {
      alert(`⚠️ Máximo ${this.MAX_PHOTOS} fotos permitidas`)
      event.target.value = ''
      return
    }

    this.updateStatus('📦 Comprimiendo imágenes en paralelo...')

    // PARALLEL COMPRESSION - All files processed simultaneously
    const compressionPromises = files.map(async (file) => {
      console.log(`${this.consolePrefixValue} Processing file:`, file.name, 'Size:', (file.size / 1024 / 1024).toFixed(2) + 'MB')

      try {
        // Comprimir imagen (uses Web Worker, truly parallel)
        const compressed = await this.compressImage(file)
        console.log(`${this.consolePrefixValue} Compressed:`, file.name, 'New size:', (compressed.size / 1024).toFixed(0) + 'KB')

        // Guardar en memoria y IndexedDB
        const photo = {
          packageId: this.packageIdValue,
          blob: compressed,
          filename: file.name,
          uploadStatus: 'pending',
          createdAt: new Date().toISOString()
        }

        // Guardar en IndexedDB (offline support)
        const id = await this.db.add(this.storeNameValue, photo)
        photo.id = id
        console.log(`${this.consolePrefixValue} Saved to IndexedDB with id:`, id)

        return { success: true, photo, filename: file.name }
      } catch (error) {
        console.error(`${this.consolePrefixValue} Error comprimiendo foto:`, error)
        return { success: false, error, filename: file.name }
      }
    })

    // Wait for ALL compressions to complete
    const results = await Promise.all(compressionPromises)

    // Process results
    results.forEach(result => {
      if (result.success) {
        this.photos.push(result.photo)
        this.addPreview(result.photo)
      } else {
        alert(`❌ Error procesando ${result.filename}`)
      }
    })

    this.updateUI()
    this.updateStatus('')
    event.target.value = ''
    console.log(`${this.consolePrefixValue} Total photos:`, this.photos.length)
  }

  // Comprimir imagen usando browser-image-compression
  async compressImage(file) {
    const options = {
      maxSizeMB: this.MAX_SIZE_MB,
      maxWidthOrHeight: this.MAX_DIMENSION,
      useWebWorker: true,  // Uses Web Worker for true parallel processing
      fileType: 'image/webp', // Mejor compresión que JPEG
      initialQuality: 0.8
    }

    try {
      const compressed = await imageCompression(file, options)
      const sizeMB = (compressed.size / 1024 / 1024).toFixed(2)
      console.log(`${this.consolePrefixValue} Comprimido: ${file.name} (${sizeMB}MB)`)
      return compressed
    } catch (error) {
      // Fallback a JPEG si WebP falla
      console.warn(`${this.consolePrefixValue} WebP falló, intentando JPEG...`, error)
      options.fileType = 'image/jpeg'
      return await imageCompression(file, options)
    }
  }

  // Subir fotos a S3 (sequential is OK for uploads - network bottleneck)
  async uploadPhotos() {
    if (this.photos.length < this.REQUIRED_FOR_UPLOAD) {
      alert(`⚠️ Se requieren al menos ${this.REQUIRED_FOR_UPLOAD} fotos para continuar.\nActualmente tienes ${this.photos.length}.`)
      return
    }

    if (this.photos.length > this.MAX_PHOTOS) {
      alert(`⚠️ Máximo ${this.MAX_PHOTOS} fotos permitidas.\nActualmente tienes ${this.photos.length}.`)
      return
    }

    this.submitTarget.disabled = true
    this.updateStatus('☁️ Subiendo fotos a S3...')

    let uploaded = 0

    for (const photo of this.photos) {
      if (photo.uploadStatus === 'uploaded') {
        uploaded++
        continue
      }

      try {
        // Direct Upload a S3
        await this.directUpload(photo)

        // Marcar como subida
        photo.uploadStatus = 'uploaded'
        await this.db.put(this.storeNameValue, photo)

        uploaded++
        this.updateStatus(`☁️ Subiendo ${uploaded}/${this.photos.length}...`)

      } catch (error) {
        console.error(`${this.consolePrefixValue} Error subiendo foto:`, error)
        this.submitTarget.disabled = false
        this.updateStatus(`❌ Error subiendo fotos`)
        alert('❌ Error al subir fotos. Verifica tu conexión e intenta nuevamente.')
        return
      }
    }

    // Todas las fotos subidas → enviar formulario
    this.updateStatus('✅ Fotos subidas correctamente')

    // Limpiar IndexedDB
    await this.clearPhotos()

    // Enviar formulario
    this.submitTarget.form.submit()
  }

  // Direct Upload usando ActiveStorage
  async directUpload(photo) {
    return new Promise((resolve, reject) => {
      const file = new File([photo.blob], photo.filename, { type: photo.blob.type })

      const upload = new DirectUpload(file, this.directUploadUrlValue)

      upload.create((error, blob) => {
        if (error) {
          reject(error)
        } else {
          // Agregar blob firmado al formulario
          this.addHiddenBlobInput(blob.signed_id)
          resolve(blob)
        }
      })
    })
  }

  // Agregar input hidden con signed_id para ActiveStorage
  addHiddenBlobInput(signedId) {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = this.inputNameValue  // Configurable per controller
    input.value = signedId
    this.submitTarget.form.appendChild(input)
  }

  // Cargar fotos pendientes de IndexedDB
  async loadPendingPhotos() {
    const pending = await this.db.getAllFromIndex(
      this.storeNameValue,  // Configurable store name
      'packageId',
      this.packageIdValue
    )

    for (const photo of pending) {
      this.photos.push(photo)
      this.addPreview(photo)
    }

    this.updateUI()
  }

  // Agregar preview (formato lista con modal)
  addPreview(photo) {
    console.log(`${this.consolePrefixValue} Adding preview for photo:`, photo.id)
    const url = URL.createObjectURL(photo.blob)
    const photoIndex = this.photos.length

    const div = document.createElement('div')
    div.className = 'flex items-center justify-between bg-white p-3 rounded-lg border-2 border-green-500 mb-2'
    div.dataset.photoId = photo.id

    div.innerHTML = `
      <div class="flex items-center gap-3 flex-1 cursor-pointer" data-photo-url="${url}">
        <img src="${url}" class="w-16 h-16 object-cover rounded border border-gray-300">
        <div>
          <p class="font-semibold text-gray-900">📷 Foto ${photoIndex}</p>
          <p class="text-xs text-gray-600">${(photo.blob.size / 1024).toFixed(0)} KB</p>
        </div>
      </div>
      <button type="button"
              class="bg-red-600 text-white rounded-full w-8 h-8 hover:bg-red-700 flex items-center justify-center font-bold text-lg"
              data-photo-id="${photo.id}"
              data-remove-btn>
        ×
      </button>
    `

    // Agregar event listeners nativos
    const clickableArea = div.querySelector('[data-photo-url]')
    clickableArea.addEventListener('click', (e) => {
      this.openPhotoModal(e)
    })

    const removeBtn = div.querySelector('[data-remove-btn]')
    removeBtn.addEventListener('click', async (e) => {
      console.log(`${this.consolePrefixValue} Remove button clicked for photo:`, photo.id)
      await this.removePhoto(e)
    })

    this.previewTarget.appendChild(div)
    console.log(`${this.consolePrefixValue} Preview added with event listeners`)
  }

  // Abrir modal para ver foto en tamaño completo
  openPhotoModal(event) {
    const photoUrl = event.currentTarget.dataset.photoUrl
    console.log(`${this.consolePrefixValue} Opening photo modal:`, photoUrl)

    // Crear modal si no existe (using configurable modalId)
    let modal = document.getElementById(this.modalIdValue)
    if (!modal) {
      modal = this.createPhotoModal()
      document.body.appendChild(modal)

      // Agregar event listeners después de crear el modal
      this.attachModalListeners(modal)
    }

    const img = modal.querySelector(`#${this.modalIdValue}-img`)
    img.src = photoUrl
    modal.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Agregar event listeners al modal
  attachModalListeners(modal) {
    console.log(`${this.consolePrefixValue} Attaching modal listeners`)

    // Cerrar al hacer click en el overlay
    const overlay = modal.querySelector('.fixed.inset-0')
    if (overlay) {
      overlay.addEventListener('click', (e) => {
        console.log(`${this.consolePrefixValue} Overlay clicked`)
        this.closePhotoModal()
      })
    }

    // Cerrar al hacer click en el botón X
    const closeBtn = modal.querySelector('button[data-modal-close]')
    if (closeBtn) {
      closeBtn.addEventListener('click', (e) => {
        console.log(`${this.consolePrefixValue} Close button clicked`)
        e.stopPropagation()
        this.closePhotoModal()
      })
    }
  }

  // Crear modal para fotos (using configurable modalId)
  createPhotoModal() {
    const modal = document.createElement('div')
    modal.id = this.modalIdValue
    modal.className = 'hidden fixed inset-0 z-50 overflow-y-auto'
    modal.setAttribute('role', 'dialog')
    modal.setAttribute('aria-modal', 'true')

    modal.innerHTML = `
      <div class="fixed inset-0 bg-black bg-opacity-90 transition-opacity"></div>
      <div class="flex min-h-screen items-center justify-center p-4">
        <div class="relative max-w-4xl w-full">
          <button type="button"
                  data-modal-close
                  class="absolute top-2 right-2 z-10 bg-red-600 hover:bg-red-700 text-white rounded-full w-12 h-12 flex items-center justify-center shadow-lg">
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <img id="${this.modalIdValue}-img"
               src=""
               alt="Vista previa de foto"
               class="w-full h-auto rounded-lg shadow-2xl">
        </div>
      </div>
    `

    console.log(`${this.consolePrefixValue} Modal created with ID: ${this.modalIdValue}`)
    return modal
  }

  // Cerrar modal de fotos
  closePhotoModal() {
    console.log(`${this.consolePrefixValue} Closing photo modal`)
    const modal = document.getElementById(this.modalIdValue)
    if (modal) {
      modal.classList.add('hidden')
      document.body.style.overflow = 'auto'
      console.log(`${this.consolePrefixValue} Modal closed`)
    } else {
      console.warn(`${this.consolePrefixValue} Modal not found`)
    }
  }

  // Remover foto
  async removePhoto(event) {
    const photoId = parseInt(event.currentTarget.dataset.photoId)
    console.log(`${this.consolePrefixValue} Removing photo with id:`, photoId)

    // Remover de array
    const initialCount = this.photos.length
    this.photos = this.photos.filter(p => p.id !== photoId)
    console.log(`${this.consolePrefixValue} Photos count: ${initialCount} → ${this.photos.length}`)

    // Remover de IndexedDB
    try {
      await this.db.delete(this.storeNameValue, photoId)
      console.log(`${this.consolePrefixValue} Deleted from IndexedDB`)
    } catch (error) {
      console.error(`${this.consolePrefixValue} Error deleting from IndexedDB:`, error)
    }

    // Remover del DOM
    const preview = this.previewTarget.querySelector(`[data-photo-id="${photoId}"]`)
    if (preview) {
      preview.remove()
      console.log(`${this.consolePrefixValue} Preview removed from DOM`)
    } else {
      console.warn(`${this.consolePrefixValue} Preview element not found in DOM`)
    }

    this.updateUI()
    console.log(`${this.consolePrefixValue} Photo removed successfully`)
  }

  // Limpiar fotos subidas
  async clearPhotos() {
    const tx = this.db.transaction(this.storeNameValue, 'readwrite')
    const index = tx.store.index('packageId')

    for await (const cursor of index.iterate(this.packageIdValue)) {
      cursor.delete()
    }

    await tx.done
  }

  // Cuando vuelve la conexión
  async onOnline() {
    console.log(`${this.consolePrefixValue} Conexión restaurada`)
    this.updateStatus('🟢 Conectado')

    // Auto-reintento si hay fotos pendientes y suficientes para subir
    const pending = this.photos.filter(p => p.uploadStatus === 'pending')
    if (pending.length > 0 && this.photos.length >= this.REQUIRED_FOR_UPLOAD) {
      setTimeout(() => this.uploadPhotos(), 2000)
    }
  }

  // Actualizar UI
  updateUI() {
    const count = this.photos.length
    this.countTarget.textContent = `${count}/${this.MAX_PHOTOS} fotos`

    // Activar botón con 1 o más fotos (hasta 4 máximo)
    if (count >= this.REQUIRED_FOR_UPLOAD && count <= this.MAX_PHOTOS) {
      this.countTarget.className = 'text-lg font-bold text-green-600'
      this.submitTarget.disabled = false
    } else {
      this.countTarget.className = 'text-lg font-bold text-orange-600'
      this.submitTarget.disabled = true
    }

    // Deshabilitar input si ya tiene el máximo de fotos
    this.inputTarget.disabled = count >= this.MAX_PHOTOS
  }

  // Actualizar mensaje de estado
  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.classList.remove('hidden')
    }
  }
}
