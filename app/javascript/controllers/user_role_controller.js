import { Controller } from "@hotwired/stimulus"

// Conecta este controller con data-controller="user-role"
export default class extends Controller {
  static targets = ["roleSelect", "adminFields", "customerFields", "driverFields"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const selectedRole = this.roleSelectTarget.value

    // Ocultar todos los grupos de campos primero
    this.hideAllFields()

    // Mostrar solo el grupo del rol seleccionado
    if (selectedRole && this[`${selectedRole}FieldsTarget`]) {
      this.showFields(selectedRole)
    }
  }

  hideAllFields() {
    ['adminFields', 'customerFields', 'driverFields'].forEach(targetName => {
      if (this[`has${this.capitalize(targetName)}Target`]) {
        const target = this[`${targetName}Target`]
        target.classList.add('hidden')
        // Deshabilitar inputs para que no se envíen
        this.disableInputs(target)
      }
    })
  }

  showFields(role) {
    const target = this[`${role}FieldsTarget`]
    target.classList.remove('hidden')
    // Habilitar inputs del rol visible
    this.enableInputs(target)

    // Scroll suave al campo y auto-focus
    target.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    const firstInput = target.querySelector('input:not([type="hidden"]):not([type="checkbox"]), select, textarea')
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 300) // Delay para animación de scroll
    }
  }

  disableInputs(container) {
    container.querySelectorAll('input:not([type="hidden"]), select, textarea').forEach(input => {
      input.disabled = true
    })
  }

  enableInputs(container) {
    container.querySelectorAll('input:not([type="hidden"]), select, textarea').forEach(input => {
      input.disabled = false
    })
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }
}
