import { Controller } from "@hotwired/stimulus"

// Controlador para manejar menús desplegables en el sidebar
export default class extends Controller {
  static targets = ["submenu", "arrow", "container"]

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  mouseEnter() {
    // Cancelar cualquier cierre pendiente
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    // Expandir inmediatamente
    this.expand()
  }

  mouseLeave() {
    // Esperar 200ms antes de colapsar (para permitir transición del mouse)
    this.timeout = setTimeout(() => {
      this.collapse()
    }, 200)
  }

  toggle(event) {
    event.preventDefault()

    if (this.submenuTarget.classList.contains('hidden')) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  expand() {
    this.submenuTarget.classList.remove('hidden')
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.add('rotate-90')
    }
  }

  collapse() {
    this.submenuTarget.classList.add('hidden')
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.remove('rotate-90')
    }
  }
}
