import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "buttonText"]

  connect() {
    this.updateButtonState()
  }

  toggleAll(event) {
    const isChecked = event.target.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })
    this.updateButtonState()
  }

  updateSelection() {
    const totalCheckboxes = this.checkboxTargets.length
    const checkedCheckboxes = this.checkboxTargets.filter(cb => cb.checked).length

    // Update "select all" checkbox state
    if (this.hasSelectAllTarget) {
      if (checkedCheckboxes === 0) {
        this.selectAllTarget.checked = false
        this.selectAllTarget.indeterminate = false
      } else if (checkedCheckboxes === totalCheckboxes) {
        this.selectAllTarget.checked = true
        this.selectAllTarget.indeterminate = false
      } else {
        this.selectAllTarget.checked = false
        this.selectAllTarget.indeterminate = true
      }
    }

    this.updateButtonState()
  }

  updateButtonState() {
    const button = document.getElementById('bulk-start-btn')

    // Si el botón no existe en esta página, no hacer nada
    if (!button) return

    const selectedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (selectedCount > 0) {
      button.disabled = false
      if (this.hasButtonTextTarget) {
        this.buttonTextTarget.textContent = `Iniciar Ruta (${selectedCount})`
      }
    } else {
      button.disabled = true
      if (this.hasButtonTextTarget) {
        this.buttonTextTarget.textContent = 'Iniciar Ruta'
      }
    }
  }

  async startRoutes() {
    const selectedIds = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    if (selectedIds.length === 0) {
      alert('Por favor seleccione al menos un conductor')
      return
    }

    if (!confirm(`¿Está seguro de iniciar rutas para ${selectedIds.length} conductor(es)?`)) {
      return
    }

    const button = document.getElementById('bulk-start-btn')
    const originalText = this.buttonTextTarget.textContent

    // Show loading state
    button.disabled = true
    this.buttonTextTarget.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Iniciando...
    `

    try {
      // Create FormData
      const formData = new FormData()
      selectedIds.forEach(id => {
        formData.append('driver_ids[]', id)
      })

      // Get CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content

      // Send request
      const response = await fetch('/admin/drivers/bulk_start_routes', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: formData
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        // Reset selection after successful processing
        this.resetSelection()
      } else {
        alert('Error al iniciar rutas. Por favor intente nuevamente.')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Error de conexión. Por favor intente nuevamente.')
    } finally {
      // Restore button state
      button.disabled = false
      this.buttonTextTarget.textContent = 'Iniciar Ruta'
      this.updateButtonState()
    }
  }

  resetSelection() {
    // Uncheck all checkboxes
    this.checkboxTargets.forEach(cb => cb.checked = false)
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    }
    this.updateButtonState()
  }
}
