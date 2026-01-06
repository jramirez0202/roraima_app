import PhotoBaseController from "./photo_base_controller"

/**
 * Controller para captura y upload de fotos de entrega
 * Hereda toda la funcionalidad de PhotoBaseController
 *
 * Características heredadas:
 * - Compresión automática paralela (5-8MB → <1MB)
 * - Persistencia offline (IndexedDB)
 * - Direct Upload a S3
 * - 2-4 fotos requeridas
 * - Reintentos automáticos
 */
export default class extends PhotoBaseController {
  async connect() {
    // Configurar valores específicos para fotos de entrega
    this.storeNameValue = 'delivery-photos'
    this.inputNameValue = 'package[proof_photos][]'
    this.modalIdValue = 'delivery-photo-modal'
    this.consolePrefixValue = '📸'

    // Llamar al connect de la clase base
    await super.connect()
  }

  // Mostrar alerta estilo flash (sin refresh)
  showFlashAlert(message, type = 'error') {
    // Remover alertas previas
    const existingAlert = document.querySelector('.flash-alert-dynamic')
    if (existingAlert) existingAlert.remove()

    const colors = {
      error: {
        bg: 'bg-red-50',
        border: 'border-red-500',
        text: 'text-red-800',
        icon: 'text-red-500'
      },
      warning: {
        bg: 'bg-yellow-50',
        border: 'border-yellow-500',
        text: 'text-yellow-800',
        icon: 'text-yellow-500'
      }
    }

    const color = colors[type] || colors.error

    const alertHTML = `
      <div class="flash-alert-dynamic mb-4 ${color.bg} border-l-4 ${color.border} p-4 rounded shadow-sm animate-fade-in">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 ${color.icon}" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
            </svg>
          </div>
          <div class="ml-3 flex-1">
            <p class="text-sm font-medium ${color.text}">${message}</p>
          </div>
          <div class="ml-auto pl-3">
            <button type="button" class="inline-flex ${color.text} hover:${color.bg} rounded-md p-1.5 focus:outline-none" onclick="this.parentElement.parentElement.parentElement.remove()">
              <span class="sr-only">Cerrar</span>
              <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    `

    // Insertar antes del formulario de cambio de estado
    const form = document.getElementById('package-status-form')
    if (form) {
      form.insertAdjacentHTML('beforebegin', alertHTML)

      // Scroll suave a la alerta
      const alert = document.querySelector('.flash-alert-dynamic')
      if (alert) {
        alert.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }

      // Auto-ocultar después de 8 segundos
      setTimeout(() => {
        const alertToRemove = document.querySelector('.flash-alert-dynamic')
        if (alertToRemove) {
          alertToRemove.style.transition = 'opacity 0.3s ease-out'
          alertToRemove.style.opacity = '0'
          setTimeout(() => alertToRemove.remove(), 300)
        }
      }, 8000)
    }
  }

  // Sobrescribir uploadPhotos para validar nombre del receptor ANTES de submit
  async uploadPhotos() {
    // VALIDACIÓN ESPECÍFICA PARA ENTREGA: Verificar nombre del receptor
    const receiverNameInput = document.getElementById('receiver_name')
    if (!receiverNameInput || !receiverNameInput.value || receiverNameInput.value.trim() === '') {
      // Mostrar alerta estilo flash
      this.showFlashAlert('Se requiere el detalles del receptor para marcar como entregado por favor.', 'error')

      // Focus en el campo para que el usuario lo vea
      if (receiverNameInput) {
        receiverNameInput.focus()
        receiverNameInput.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
      return // NO continuar con el upload
    }

    // Agregar campos del receptor al formulario como hidden inputs antes de submit
    const receiverObservationsInput = document.getElementById('receiver_observations')
    const form = this.submitTarget.form

    // Remover inputs previos si existen (para evitar duplicados)
    const oldReceiverName = form.querySelector('input[name="receiver_name"]')
    if (oldReceiverName) oldReceiverName.remove()
    const oldReceiverObs = form.querySelector('input[name="receiver_observations"]')
    if (oldReceiverObs) oldReceiverObs.remove()

    // Agregar receiver_name
    const receiverNameHidden = document.createElement('input')
    receiverNameHidden.type = 'hidden'
    receiverNameHidden.name = 'receiver_name'
    receiverNameHidden.value = receiverNameInput.value.trim()
    form.appendChild(receiverNameHidden)

    // Agregar receiver_observations (opcional)
    if (receiverObservationsInput && receiverObservationsInput.value.trim() !== '') {
      const receiverObsHidden = document.createElement('input')
      receiverObsHidden.type = 'hidden'
      receiverObsHidden.name = 'receiver_observations'
      receiverObsHidden.value = receiverObservationsInput.value.trim()
      form.appendChild(receiverObsHidden)
    }

    // Si la validación pasa, llamar al método original de la clase base
    await super.uploadPhotos()
  }
}
