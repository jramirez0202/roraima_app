import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "main"]

  connect() {
    console.log('🎯 Sidebar controller connected')
    console.log('Has main target:', this.hasMainTarget)

    // Restaurar estado del sidebar desde localStorage
    const sidebarClosed = localStorage.getItem('sidebarClosed') === 'true'
    console.log('Sidebar closed from localStorage:', sidebarClosed)

    if (sidebarClosed) {
      // Si el usuario cerró el sidebar previamente, mantenerlo cerrado
      this.sidebarTarget.classList.add('-translate-x-full')
      // Quitar el margin del main cuando el sidebar está cerrado
      if (this.hasMainTarget) {
        this.mainTarget.classList.remove('md:ml-80')
      }
    } else {
      // Sidebar abierto por defecto - asegurar que main tenga margin
      if (this.hasMainTarget) {
        this.mainTarget.classList.add('md:ml-80')
      }
    }

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
    // Mostrar overlay (solo visible en mobile por CSS)
    this.overlayTarget.classList.remove('hidden')

    // Slide in sidebar
    this.sidebarTarget.classList.remove('-translate-x-full')

    // Agregar margin al main en desktop
    if (this.hasMainTarget) {
      this.mainTarget.classList.add('md:ml-80')
    }

    // Guardar estado en localStorage
    localStorage.setItem('sidebarClosed', 'false')

    // Prevenir scroll del body solo en mobile (cuando hay overlay)
    if (window.innerWidth < 768) {
      document.body.style.overflow = 'hidden'
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    // Ocultar overlay
    this.overlayTarget.classList.add('hidden')

    // Slide out sidebar
    this.sidebarTarget.classList.add('-translate-x-full')

    // Quitar margin del main en desktop
    if (this.hasMainTarget) {
      this.mainTarget.classList.remove('md:ml-80')
    }

    // Guardar estado en localStorage
    localStorage.setItem('sidebarClosed', 'true')

    // Restaurar scroll del body
    document.body.style.overflow = ''
  }
}
