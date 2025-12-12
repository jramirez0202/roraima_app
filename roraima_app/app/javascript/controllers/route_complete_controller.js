import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    pendingCount: Number
  }

  showModal() {
    const pendingCount = this.pendingCountValue

    // Mensaje de confirmación basado en paquetes pendientes
    let message = "¿Estás seguro de que deseas finalizar la ruta?"
    if (pendingCount > 0) {
      message = `⚠️ Aún tienes ${pendingCount} paquete${pendingCount > 1 ? 's' : ''} sin entregar.\n\n¿Deseas continuar y finalizar la ruta?`
    }

    const confirmed = confirm(message)

    if (confirmed) {
      // Solicitar comentario opcional
      const notes = prompt("Comentario opcional (presiona Enter para omitir):", "")

      // Si el usuario cancela el prompt, no hacer nada
      if (notes === null) return

      // Enviar POST a complete_route
      this.submitCompleteRoute(notes)
    }
  }

  submitCompleteRoute(notes) {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/drivers/complete_route'

    // CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    // Notes parameter
    if (notes && notes.trim() !== '') {
      const notesInput = document.createElement('input')
      notesInput.type = 'hidden'
      notesInput.name = 'notes'
      notesInput.value = notes.trim()
      form.appendChild(notesInput)
    }

    // Accept turbo streams
    form.setAttribute('data-turbo', 'true')

    document.body.appendChild(form)
    form.submit()
  }
}
