import { Controller } from "@hotwired/stimulus"

/**
 * Controller para persistir datos del formulario de receptor
 *
 * Características:
 * - Persistencia automática en sessionStorage (se limpia al cerrar pestaña)
 * - Restauración automática al cargar la página
 * - Limpieza automática después de submit exitoso
 * - Compatible con Turbo Drive
 *
 * Uso en la vista:
 *   <div data-controller="receiver-form">
 *     <input data-receiver-form-target="receiverName" data-action="input->receiver-form#persistField">
 *     <textarea data-receiver-form-target="receiverObservations" data-action="input->receiver-form#persistField">
 *   </div>
 */
export default class extends Controller {
  static targets = ["receiverName", "receiverObservations", "nameCounter"]
  static values = { packageId: Number }

  connect() {
    // Restaurar valores desde sessionStorage al cargar
    this.restoreFields()

    // Detectar si venimos de un submit exitoso y limpiar
    this.cleanupAfterSuccess()

    // Inicializar contador si existe
    if (this.hasNameCounterTarget && this.hasReceiverNameTarget) {
      this.updateCounter()
    }
  }

  /**
   * Persiste el valor del campo en sessionStorage
   * Se ejecuta en cada input (con debounce automático del navegador)
   */
  persistField(event) {
    const field = event.target
    const key = this.getStorageKey(field.id)

    if (field.value.trim() === '') {
      // Si está vacío, remover de storage
      sessionStorage.removeItem(key)
    } else {
      // Persistir valor con timestamp
      const data = {
        value: field.value,
        timestamp: Date.now()
      }
      sessionStorage.setItem(key, JSON.stringify(data))
    }

    // Actualizar contador si es el campo receiver_name
    if (field.id === 'receiver_name' && this.hasNameCounterTarget) {
      this.updateCounter()
    }
  }

  /**
   * Actualiza el contador de caracteres para receiver_name
   */
  updateCounter() {
    if (this.hasReceiverNameTarget && this.hasNameCounterTarget) {
      const length = this.receiverNameTarget.value.length
      this.nameCounterTarget.textContent = length
    }
  }

  /**
   * Restaura los valores de los campos desde sessionStorage
   */
  restoreFields() {
    const MAX_AGE_HOURS = 24 // Datos más antiguos de 24 horas se descartan

    // Restaurar receiver_name
    if (this.hasReceiverNameTarget) {
      const savedData = this.getStoredValue('receiver_name')
      if (savedData && !this.isDataExpired(savedData, MAX_AGE_HOURS)) {
        this.receiverNameTarget.value = savedData.value
        this.showRestoredFeedback(this.receiverNameTarget)
      }
    }

    // Restaurar receiver_observations
    if (this.hasReceiverObservationsTarget) {
      const savedData = this.getStoredValue('receiver_observations')
      if (savedData && !this.isDataExpired(savedData, MAX_AGE_HOURS)) {
        this.receiverObservationsTarget.value = savedData.value
        this.showRestoredFeedback(this.receiverObservationsTarget)
      }
    }
  }

  /**
   * Obtiene un valor del sessionStorage y lo parsea
   */
  getStoredValue(fieldName) {
    const key = this.getStorageKey(fieldName)
    const stored = sessionStorage.getItem(key)

    if (!stored) return null

    try {
      // Intentar parsear como JSON (nuevo formato)
      return JSON.parse(stored)
    } catch {
      // Fallback: formato antiguo (solo string)
      return { value: stored, timestamp: Date.now() }
    }
  }

  /**
   * Verifica si los datos están expirados
   */
  isDataExpired(data, maxAgeHours) {
    if (!data.timestamp) return false // Sin timestamp = no expira

    const ageHours = (Date.now() - data.timestamp) / (1000 * 60 * 60)
    return ageHours > maxAgeHours
  }

  /**
   * Muestra feedback visual cuando se restaura un valor
   */
  showRestoredFeedback(field) {
    // Agregar clase de highlight temporal
    field.classList.add('bg-yellow-50', 'border-yellow-300')

    // Remover highlight después de 2 segundos
    setTimeout(() => {
      field.classList.remove('bg-yellow-50', 'border-yellow-300')
    }, 2000)
  }

  /**
   * Limpia sessionStorage si detectamos que venimos de un submit exitoso
   * o si el paquete ya está en estado final
   */
  cleanupAfterSuccess() {
    // Detectar flash notice (submit exitoso)
    const flashNotice = document.querySelector('.alert-success, [role="alert"].bg-green-50, .notice')

    if (flashNotice && flashNotice.textContent.includes('Estado actualizado correctamente')) {
      this.clearStorage()
      return
    }

    // Si el paquete ya está entregado/cancelado, limpiar storage de este paquete
    const statusBadge = document.querySelector('.badge-delivered, .badge-cancelled, .bg-green-100')
    if (statusBadge) {
      this.clearStorage()
    }
  }

  /**
   * Limpia todos los datos de receiver_form del sessionStorage
   */
  clearStorage() {
    sessionStorage.removeItem(this.getStorageKey('receiver_name'))
    sessionStorage.removeItem(this.getStorageKey('receiver_observations'))
  }

  /**
   * Genera una key única para sessionStorage
   * Incluye package_id para evitar colisiones entre paquetes
   */
  getStorageKey(fieldName) {
    const packageId = this.hasPackageIdValue ? this.packageIdValue : 'unknown'
    return `receiver_form_${packageId}_${fieldName}`
  }

  /**
   * Limpia el storage al desconectar (opcional, sessionStorage ya se limpia al cerrar pestaña)
   */
  disconnect() {
    // Cleanup automático al cerrar pestaña
  }
}
