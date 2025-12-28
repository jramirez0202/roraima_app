import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    pendingCount: Number
  }

  showModal() {
    // Solo una alerta de confirmación
    const confirmed = confirm("¿Estás seguro de que deseas finalizar la ruta?")

    if (confirmed) {
      // Enviar POST a complete_route sin comentarios
      this.submitCompleteRoute('')
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
