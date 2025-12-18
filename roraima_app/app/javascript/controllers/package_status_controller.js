import { Controller } from "@hotwired/stimulus"

// Controlador para manejar el cambio de estado de paquetes desde la vista de drivers
export default class extends Controller {
  static targets = [
    "statusSelect",
    "reasonField",
    "proofField",
    "photoInput",
    "photosContainer",
    "compressionStatus",
    "proofData",
    "form"
  ]

  static values = {
    maxPhotos: { type: Number, default: 4 }
  }

  connect() {
    console.log('📦 PackageStatusController connected')
    console.log('Form target:', this.formTarget)
    console.log('Status select target:', this.statusSelectTarget)
    this.compressedPhotos = []
    this.toggleFields()
  }

  disconnect() {
    // Limpiar al salir
    this.compressedPhotos = []
  }

  // Toggle de campos según el estado seleccionado
  toggleFields() {
    const status = this.statusSelectTarget.value
    console.log('🔄 toggleFields called, status:', status)
    const needsReason = ['cancelled', 'rescheduled'].includes(status)
    const needsProof = status === 'delivered'
    console.log('needsProof:', needsProof, 'needsReason:', needsReason)

    this.reasonFieldTarget.style.display = needsReason ? 'block' : 'none'
    this.proofFieldTarget.style.display = needsProof ? 'block' : 'none'

    // Actualizar label según el estado
    const proofLabel = this.proofFieldTarget.querySelector('label')
    if (proofLabel) {
      if (status === 'delivered') {
        proofLabel.textContent = 'Fotos de Evidencia de Entrega (Máximo 4)'
      } else if (status === 'rescheduled') {
        proofLabel.textContent = 'Fotos de Evidencia de Visita (Máximo 4)'
      }
    }

    // Actualizar required del textarea
    const reasonTextarea = this.reasonFieldTarget.querySelector('textarea')
    if (reasonTextarea) {
      reasonTextarea.required = needsReason
    }

    // Manejo de campos específicos de la vista admin (si existen)
    const enCaminoFields = document.getElementById('en-camino-fields')
    const reprogramadoFields = document.getElementById('reprogramado-fields')
    const locationSuggestions = document.getElementById('location-suggestions')

    if (enCaminoFields) {
      if (status === 'in_transit') {
        enCaminoFields.classList.remove('hidden')
        const courierId = document.getElementById('courier_id')
        if (courierId) courierId.required = true
      } else {
        enCaminoFields.classList.add('hidden')
        const courierId = document.getElementById('courier_id')
        if (courierId) courierId.required = false
      }
    }

    if (reprogramadoFields) {
      const motiveField = document.getElementById('motive')
      if (status === 'rescheduled') {
        reprogramadoFields.classList.remove('hidden')
        if (motiveField) motiveField.required = true
      } else {
        reprogramadoFields.classList.add('hidden')
        if (motiveField) motiveField.required = false
      }
    }

    if (locationSuggestions) {
      if (status === 'in_warehouse') {
        locationSuggestions.classList.remove('hidden')
      } else {
        locationSuggestions.classList.add('hidden')
      }
    }
  }

  // Manejo de selección de fotos
  handlePhotoInput(event) {
    const files = Array.from(event.target.files)

    // Validar límite de fotos
    if (this.compressedPhotos.length + files.length > this.maxPhotosValue) {
      alert(`Solo puedes subir un máximo de ${this.maxPhotosValue} fotos. Actualmente tienes ${this.compressedPhotos.length} foto(s).`)
      this.photoInputTarget.value = ''
      return
    }

    if (files.length > 0) {
      this.compressionStatusTarget.style.display = 'block'

      let processedCount = 0
      files.forEach((file) => {
        this.compressImage(file, (compressedDataUrl, originalSize, compressedSize) => {
          this.compressedPhotos.push(compressedDataUrl)
          this.addPhotoPreview(compressedDataUrl, compressedSize)

          processedCount++
          if (processedCount === files.length) {
            this.compressionStatusTarget.style.display = 'none'
            this.updateProofData()
            this.photoInputTarget.value = ''
          }
        })
      })
    }
  }

  // Agregar preview de foto
  addPhotoPreview(dataUrl, sizeKB) {
    const photoDiv = document.createElement('div')
    photoDiv.className = 'relative'
    photoDiv.innerHTML = `
      <img src="${dataUrl}" class="w-full h-32 object-cover rounded border border-gray-200">
      <button type="button"
              data-action="click->package-status#removePhoto"
              data-index="${this.compressedPhotos.length - 1}"
              class="absolute top-1 right-1 bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-700">
        ×
      </button>
      <p class="text-xs text-green-600 mt-1">${sizeKB}KB</p>
    `
    this.photosContainerTarget.appendChild(photoDiv)
  }

  // Eliminar una foto
  removePhoto(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.compressedPhotos.splice(index, 1)
    this.refreshPhotosPreviews()
    this.updateProofData()
  }

  // Refrescar los previews de fotos
  refreshPhotosPreviews() {
    this.photosContainerTarget.innerHTML = ''

    this.compressedPhotos.forEach((photo, idx) => {
      const sizeKB = Math.round(photo.length * 0.75 / 1024)
      const photoDiv = document.createElement('div')
      photoDiv.className = 'relative'
      photoDiv.innerHTML = `
        <img src="${photo}" class="w-full h-32 object-cover rounded border border-gray-200">
        <button type="button"
                data-action="click->package-status#removePhoto"
                data-index="${idx}"
                class="absolute top-1 right-1 bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-700">
          ×
        </button>
        <p class="text-xs text-green-600 mt-1">${sizeKB}KB</p>
      `
      this.photosContainerTarget.appendChild(photoDiv)
    })
  }

  // Actualizar el campo hidden con el JSON de fotos
  updateProofData() {
    this.proofDataTarget.value = JSON.stringify(this.compressedPhotos)
  }

  // Validar el formulario antes de enviar
  validateForm(event) {
    console.log('📋 validateForm ejecutándose...')

    const status = this.statusSelectTarget.value
    console.log('Estado seleccionado:', status)

    // Verificar si el override está activado (solo en vista admin)
    const overrideCheckbox = document.querySelector('input[name="override"]')
    const isOverride = overrideCheckbox && overrideCheckbox.checked

    console.log('Override checkbox encontrado:', !!overrideCheckbox, 'checked:', isOverride)

    // Si el override está activado, saltar todas las validaciones
    if (isOverride) {
      console.log('🔓 Admin override activado - saltando validaciones')
      // Permitir que el formulario se envíe sin bloqueos
      return
    }

    // Validar que se haya seleccionado un estado
    if (!status || status === '') {
      event.preventDefault()
      alert('Por favor, selecciona un estado antes de continuar.')
      return false
    }

    // Validar fotos para "entregado"
    if (status === 'delivered') {
      if (this.compressedPhotos.length === 0) {
        event.preventDefault()
        alert('Por favor, proporciona al menos una foto de evidencia antes de continuar.')
        return false
      }
    }

    // Validar motivo para "cancelado" o "reprogramado"
    if (status === 'cancelled' || status === 'rescheduled') {
      const reasonTextarea = this.reasonFieldTarget.querySelector('textarea')
      if (!reasonTextarea || !reasonTextarea.value || reasonTextarea.value.trim() === '') {
        event.preventDefault()
        alert('Por favor, proporciona un motivo antes de continuar.')
        return false
      }
    }

    // Validar courier para "in_transit" (solo en vista admin)
    if (status === 'in_transit') {
      const courierId = document.getElementById('courier_id')
      if (courierId && (!courierId.value || courierId.value === '')) {
        event.preventDefault()
        alert('Por favor, asigna un driver antes de marcar como "En Camino".')
        return false
      }
    }

    // Si llegamos aquí, todas las validaciones pasaron
    return true
  }

  // Comprimir imagen
  compressImage(file, callback) {
    const reader = new FileReader()

    reader.onload = (e) => {
      const img = new Image()

      img.onload = () => {
        const MAX_WIDTH = 800
        const MAX_HEIGHT = 800
        const QUALITY = 0.6

        let width = img.width
        let height = img.height

        // Redimensionar manteniendo aspect ratio
        if (width > height) {
          if (width > MAX_WIDTH) {
            height *= MAX_WIDTH / width
            width = MAX_WIDTH
          }
        } else {
          if (height > MAX_HEIGHT) {
            width *= MAX_HEIGHT / height
            height = MAX_HEIGHT
          }
        }

        // Crear canvas temporal
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')

        // Dibujar imagen redimensionada
        ctx.drawImage(img, 0, 0, width, height)

        // Convertir a JPEG comprimido
        const compressedDataUrl = canvas.toDataURL('image/jpeg', QUALITY)

        // Calcular tamaños
        const originalSize = Math.round(e.target.result.length * 0.75 / 1024)
        const compressedSize = Math.round(compressedDataUrl.length * 0.75 / 1024)

        console.log(`📸 Imagen comprimida: ${originalSize}KB → ${compressedSize}KB (${Math.round((compressedSize/originalSize)*100)}%)`)

        callback(compressedDataUrl, originalSize, compressedSize)
      }

      img.src = e.target.result
    }

    reader.readAsDataURL(file)
  }
}
