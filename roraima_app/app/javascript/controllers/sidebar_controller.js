import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    console.log('🎯 Sidebar Controller connected')

    // Cerrar con tecla ESC
    this.escapeHandler = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener('keydown', this.escapeHandler)
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      const isOpen = !this.sidebarTarget.classList.contains('-translate-x-full')
      if (isOpen) {
        this.close()
      }
    }
  }

  toggle() {
    const isOpen = !this.sidebarTarget.classList.contains('-translate-x-full')

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    console.log('🚀 Abriendo sidebar')
    console.log('Clases ANTES de abrir:', this.sidebarTarget.className)

    // Mostrar overlay
    this.overlayTarget.classList.remove('hidden')

    // Slide in sidebar
    this.sidebarTarget.classList.remove('-translate-x-full')

    console.log('Clases DESPUÉS de abrir:', this.sidebarTarget.className)
    console.log('¿Tiene -translate-x-full después de remover?', this.sidebarTarget.classList.contains('-translate-x-full'))

    // Prevenir scroll del body
    document.body.style.overflow = 'hidden'
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    console.log('🚪 Cerrando sidebar')
    console.log('Clases ANTES:', this.sidebarTarget.className)

    // Ocultar overlay
    this.overlayTarget.classList.add('hidden')

    // Slide out sidebar
    this.sidebarTarget.classList.add('-translate-x-full')

    console.log('Clases DESPUÉS:', this.sidebarTarget.className)
    console.log('¿Tiene -translate-x-full?', this.sidebarTarget.classList.contains('-translate-x-full'))

    // Restaurar scroll del body
    document.body.style.overflow = ''
  }

  // Cerrar al hacer click en un link
  handleLinkClick() {
    this.close()
  }
}
