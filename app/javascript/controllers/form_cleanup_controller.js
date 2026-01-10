import { Controller } from "@hotwired/stimulus"

/**
 * Controller para limpiar sessionStorage después de submit exitoso
 *
 * Se conecta en páginas de destino después de un redirect exitoso
 * (ej: drivers dashboard después de cambiar estado de paquete)
 *
 * Uso en la vista:
 *   <div data-controller="form-cleanup">
 */
export default class extends Controller {
  connect() {
    // Detectar si hay un mensaje de éxito en la página
    this.cleanupIfSuccess()
  }

  cleanupIfSuccess() {
    // Buscar flash messages de éxito en múltiples selectores
    const flashSelectors = [
      '.alert-success',
      '[role="alert"].bg-green-50',
      '.bg-green-100',
      '.notice',
      '.flash-notice',
      '[data-flash="notice"]'
    ]

    let flashNotice = null
    for (const selector of flashSelectors) {
      flashNotice = document.querySelector(selector)
      if (flashNotice) break
    }

    if (!flashNotice) return

    // Verificar si el mensaje es de éxito para cambio de estado
    const successMessages = [
      'Estado actualizado correctamente',
      'Paquete actualizado',
      'Entrega registrada',
      'Estado del paquete actualizado'
    ]

    const hasSuccessMessage = successMessages.some(msg =>
      flashNotice.textContent.includes(msg)
    )

    if (hasSuccessMessage) {
      this.clearReceiverFormStorage()
    }
  }

  /**
   * Limpia todos los datos de receiver_form del sessionStorage
   * Usa pattern matching para limpiar todos los paquetes
   */
  clearReceiverFormStorage() {
    const keysToRemove = []

    // Iterar sobre todas las keys de sessionStorage
    for (let i = 0; i < sessionStorage.length; i++) {
      const key = sessionStorage.key(i)

      // Si la key empieza con 'receiver_form_', marcarla para eliminar
      if (key && key.startsWith('receiver_form_')) {
        keysToRemove.push(key)
      }
    }

    // Eliminar todas las keys marcadas
    keysToRemove.forEach(key => {
      sessionStorage.removeItem(key)
    })
  }
}
