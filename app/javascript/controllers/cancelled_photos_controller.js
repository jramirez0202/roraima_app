import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import imageCompression from "browser-image-compression"
import { openDB } from "idb"

/**
 * Controller profesional para captura y upload de fotos de cancelación
 *
 * Características:
 * - Compresión automática (5-8MB → <1MB)
 * - Persistencia offline (IndexedDB)
 * - Direct Upload a S3
 * - Mínimo 2 fotos, máximo 4
 * - Reintentos automáticos
 */
export default class extends Controller {
  static targets = ["input", "preview", "count", "submit", "status"]
  static values = {
    packageId: Number,
    directUploadUrl: String
  }

  async connect() {
    console.log('❌ Cancelled photos controller CONNECTING...')

    this.MIN_PHOTOS = 1
    this.REQUIRED_FOR_UPLOAD = 2  // Mínimo para activar botón de subir
    this.MAX_PHOTOS = 4
    this.MAX_SIZE_MB = 0.8
    this.MAX_DIMENSION = 1600
    this.photos = []

    try {
      // Inicializar IndexedDB
      this.db = await this.initDB()
      console.log('✅ IndexedDB initialized')

      // Cargar fotos pendientes
      await this.loadPendingPhotos()
      console.log('✅ Pending photos loaded')

      // Listener de conexión
      window.addEventListener('online', () => this.onOnline())

      console.log('❌ Cancelled photos controller CONNECTED successfully')
    } catch (error) {
      console.error('❌ Error connecting cancelled photos controller:', error)
    }
  }

  // Inicializar IndexedDB
  async initDB() {
    return await openDB('roraima-delivery', 2, {
      upgrade(db) {
        // Crear store para fotos de entrega
        if (!db.objectStoreNames.contains('delivery-photos')) {
          const store = db.createObjectStore('delivery-photos', { keyPath: 'id', autoIncrement: true })
          store.createIndex('packageId', 'packageId')
          store.createIndex('uploadStatus', 'uploadStatus')
        }
        // Crear store para fotos de reprogramación
        if (!db.objectStoreNames.contains('reschedule-photos')) {
          const store = db.createObjectStore('reschedule-photos', { keyPath: 'id', autoIncrement: true })
          store.createIndex('packageId', 'packageId')
          store.createIndex('uploadStatus', 'uploadStatus')
        }
        // Crear store para fotos de cancelación
        if (!db.objectStoreNames.contains('cancelled-photos')) {
          const store = db.createObjectStore('cancelled-photos', { keyPath: 'id', autoIncrement: true })
          store.createIndex('packageId', 'packageId')
          store.createIndex('uploadStatus', 'uploadStatus')
        }
      }
    })
  }

  // Capturar foto desde input
  async capturePhoto(event) {
    console.log('📸 capturePhoto called')
    const files = Array.from(event.target.files)
    console.log('📷 Files selected:', files.length)

    if (files.length === 0) {
      console.log('⚠️ No files selected')
      return
    }

    if (this.photos.length + files.length > this.MAX_PHOTOS) {
      alert(`⚠️ Máximo ${this.MAX_PHOTOS} fotos permitidas`)
      event.target.value = ''
      return
    }

    this.updateStatus('📦 Comprimiendo imágenes...')

    for (const file of files) {
      console.log('🔄 Processing file:', file.name, 'Size:', (file.size / 1024 / 1024).toFixed(2) + 'MB')

      try {
        // Comprimir imagen
        const compressed = await this.compressImage(file)
        console.log('✅ Compressed:', file.name, 'New size:', (compressed.size / 1024).toFixed(0) + 'KB')

        // Guardar en memoria y IndexedDB
        const photo = {
          packageId: this.packageIdValue,
          blob: compressed,
          filename: file.name,
          uploadStatus: 'pending',
          createdAt: new Date().toISOString()
        }

        // Guardar en IndexedDB (offline support)
        const id = await this.db.add('cancelled-photos', photo)
        photo.id = id
        console.log('💾 Saved to IndexedDB with id:', id)

        this.photos.push(photo)
        this.addPreview(photo)

      } catch (error) {
        console.error('❌ Error comprimiendo foto:', error)
        alert(`❌ Error procesando ${file.name}`)
      }
    }

    this.updateUI()
    this.updateStatus('')
    event.target.value = ''
    console.log('✅ Total photos:', this.photos.length)
  }

  // Comprimir imagen usando browser-image-compression
  async compressImage(file) {
    const options = {
      maxSizeMB: this.MAX_SIZE_MB,
      maxWidthOrHeight: this.MAX_DIMENSION,
      useWebWorker: true,
      fileType: 'image/webp', // Mejor compresión que JPEG
      initialQuality: 0.8
    }

    try {
      const compressed = await imageCompression(file, options)
      const sizeMB = (compressed.size / 1024 / 1024).toFixed(2)
      console.log(`✅ Comprimido: ${file.name} (${sizeMB}MB)`)
      return compressed
    } catch (error) {
      // Fallback a JPEG si WebP falla
      console.warn('WebP falló, intentando JPEG...', error)
      options.fileType = 'image/jpeg'
      return await imageCompression(file, options)
    }
  }

  // Subir fotos a S3
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
        await this.db.put('cancelled-photos', photo)

        uploaded++
        this.updateStatus(`☁️ Subiendo ${uploaded}/${this.photos.length}...`)

      } catch (error) {
        console.error('Error subiendo foto:', error)
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
    input.name = 'cancelled_photos[]'
    input.value = signedId
    this.submitTarget.form.appendChild(input)
  }

  // Cargar fotos pendientes de IndexedDB
  async loadPendingPhotos() {
    const pending = await this.db.getAllFromIndex(
      'cancelled-photos',
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
    console.log('🖼️ Adding preview for photo:', photo.id)
    const url = URL.createObjectURL(photo.blob)
    const photoIndex = this.photos.length

    const div = document.createElement('div')
    div.className = 'flex items-center justify-between bg-white p-3 rounded-lg border-2 border-red-500 mb-2'
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
      console.log('🗑️ Remove button clicked for photo:', photo.id)
      await this.removePhoto(e)
    })

    this.previewTarget.appendChild(div)
    console.log('✅ Preview added with event listeners')
  }

  // Abrir modal para ver foto en tamaño completo
  openPhotoModal(event) {
    const photoUrl = event.currentTarget.dataset.photoUrl
    console.log('🔍 Opening photo modal:', photoUrl)

    // Crear modal si no existe
    let modal = document.getElementById('delivery-photo-modal')
    if (!modal) {
      modal = this.createPhotoModal()
      document.body.appendChild(modal)

      // Agregar event listeners después de crear el modal
      this.attachModalListeners(modal)
    }

    const img = modal.querySelector('#delivery-photo-modal-img')
    img.src = photoUrl
    modal.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Agregar event listeners al modal
  attachModalListeners(modal) {
    console.log('📎 Attaching modal listeners')

    // Cerrar al hacer click en el overlay
    const overlay = modal.querySelector('.fixed.inset-0')
    if (overlay) {
      overlay.addEventListener('click', (e) => {
        console.log('🖱️ Overlay clicked')
        this.closePhotoModal()
      })
    }

    // Cerrar al hacer click en el botón X
    const closeBtn = modal.querySelector('button[data-modal-close]')
    if (closeBtn) {
      closeBtn.addEventListener('click', (e) => {
        console.log('🖱️ Close button clicked')
        e.stopPropagation()
        this.closePhotoModal()
      })
    }
  }

  // Crear modal para fotos
  createPhotoModal() {
    const modal = document.createElement('div')
    modal.id = 'delivery-photo-modal'
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
          <img id="delivery-photo-modal-img"
               src=""
               alt="Vista previa de foto"
               class="w-full h-auto rounded-lg shadow-2xl">
        </div>
      </div>
    `

    console.log('✅ Modal created')
    return modal
  }

  // Cerrar modal de fotos
  closePhotoModal() {
    console.log('🚪 Closing photo modal')
    const modal = document.getElementById('delivery-photo-modal')
    if (modal) {
      modal.classList.add('hidden')
      document.body.style.overflow = 'auto'
      console.log('✅ Modal closed')
    } else {
      console.warn('⚠️ Modal not found')
    }
  }

  // Remover foto
  async removePhoto(event) {
    const photoId = parseInt(event.currentTarget.dataset.photoId)
    console.log('🗑️ Removing photo with id:', photoId)

    // Remover de array
    const initialCount = this.photos.length
    this.photos = this.photos.filter(p => p.id !== photoId)
    console.log(`📊 Photos count: ${initialCount} → ${this.photos.length}`)

    // Remover de IndexedDB
    try {
      await this.db.delete('cancelled-photos', photoId)
      console.log('💾 Deleted from IndexedDB')
    } catch (error) {
      console.error('❌ Error deleting from IndexedDB:', error)
    }

    // Remover del DOM
    const preview = this.previewTarget.querySelector(`[data-photo-id="${photoId}"]`)
    if (preview) {
      preview.remove()
      console.log('✅ Preview removed from DOM')
    } else {
      console.warn('⚠️ Preview element not found in DOM')
    }

    this.updateUI()
    console.log('✅ Photo removed successfully')
  }

  // Limpiar fotos subidas
  async clearPhotos() {
    const tx = this.db.transaction('cancelled-photos', 'readwrite')
    const index = tx.store.index('packageId')

    for await (const cursor of index.iterate(this.packageIdValue)) {
      cursor.delete()
    }

    await tx.done
  }

  // Cuando vuelve la conexión
  async onOnline() {
    console.log('🟢 Conexión restaurada')
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

    // Activar botón con 2 o más fotos (hasta 4 máximo)
    if (count >= this.REQUIRED_FOR_UPLOAD && count <= this.MAX_PHOTOS) {
      this.countTarget.className = 'text-lg font-bold text-green-600'
      this.submitTarget.disabled = false
    } else if (count === 1) {
      this.countTarget.className = 'text-lg font-bold text-blue-600'
      this.submitTarget.disabled = true
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
