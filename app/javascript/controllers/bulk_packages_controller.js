import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "checkbox",
    "selectAll",
    "bulkStatusBtn",
    "generateLabelsBtn",
    "modal",
    "selectedCount",
    "statusGrid",
    "applyBtn"
  ]

  static values = {
    translations: Object,
    badgeClasses: Object
  }

  connect() {
    console.log('📦 Bulk Packages Controller connected')
    console.log('  - Translations:', Object.keys(this.translationsValue).length, 'statuses')
    console.log('  - Badge Classes:', Object.keys(this.badgeClassesValue).length, 'statuses')
    this.selectedStatus = null
    this.selectedPackageIds = []
    this.updateButtons()
  }

  disconnect() {
    console.log('📦 Bulk Packages Controller disconnected')
    document.removeEventListener('keydown', this.handleEscape)
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateButtons()
  }

  updateButtons() {
    const selectedCount = this.getSelectedCount()

    if (selectedCount > 0) {
      this.bulkStatusBtnTarget.classList.remove('hidden')
      this.generateLabelsBtnTarget.classList.remove('hidden')
      this.bulkStatusBtnTarget.querySelector('span').textContent =
        `Cambiar Estado (${selectedCount} seleccionados)`
    } else {
      this.bulkStatusBtnTarget.classList.add('hidden')
      this.generateLabelsBtnTarget.classList.add('hidden')
    }
  }

  getSelectedCount() {
    return this.checkboxTargets.filter(cb => cb.checked).length
  }

  getSelectedIds() {
    return this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }

  // Open modal
  openModal() {
    const count = this.getSelectedCount()
    if (count === 0) {
      alert('Selecciona al menos un paquete')
      return
    }

    this.selectedPackageIds = this.getSelectedIds()
    this.selectedCountTarget.textContent =
      `${count} paquete${count > 1 ? 's' : ''} seleccionado${count > 1 ? 's' : ''}`

    this.renderStatusOptions()
    this.selectedStatus = null
    this.applyBtnTarget.disabled = true

    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'

    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.handleEscape)
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.selectedStatus = null
    this.selectedPackageIds = []
    document.removeEventListener('keydown', this.handleEscape)
  }

  handleEscape(e) {
    if (e.key === 'Escape') {
      this.closeModal()
    }
  }

  renderStatusOptions() {
    const statusKeys = ['in_warehouse', 'in_transit', 'delivered', 'rescheduled', 'return', 'cancelled']
    this.statusGridTarget.innerHTML = ''

    statusKeys.forEach(statusKey => {
      const card = this.createStatusCard(statusKey)
      this.statusGridTarget.appendChild(card)
    })
  }

  createStatusCard(statusKey) {
    const label = this.translationsValue[statusKey]
    const classes = this.badgeClassesValue[statusKey]

    const card = document.createElement('button')
    card.type = 'button'
    card.className = `relative flex items-center justify-center px-4 py-3 rounded-lg border-2 transition-all duration-150 ${classes} hover:shadow-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500`
    card.dataset.statusKey = statusKey
    card.dataset.action = "click->bulk-packages#selectStatus"

    card.innerHTML = `
      <span class="font-medium text-sm">${label}</span>
      <svg class="hidden absolute top-2 right-2 h-5 w-5 text-current check-icon" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>
    `

    return card
  }

  selectStatus(event) {
    const button = event.currentTarget
    this.selectedStatus = button.dataset.statusKey

    // Update visual selection
    this.statusGridTarget.querySelectorAll('button').forEach(card => {
      const checkIcon = card.querySelector('.check-icon')
      if (card.dataset.statusKey === this.selectedStatus) {
        card.classList.add('ring-2', 'ring-offset-2', 'ring-indigo-600', 'shadow-lg')
        checkIcon.classList.remove('hidden')
      } else {
        card.classList.remove('ring-2', 'ring-offset-2', 'ring-indigo-600', 'shadow-lg')
        checkIcon.classList.add('hidden')
      }
    })

    this.applyBtnTarget.disabled = false
  }

  async applyBulkChange() {
    if (!this.selectedStatus || this.selectedPackageIds.length === 0) {
      alert('Debes seleccionar un estado')
      return
    }

    const statusLabel = this.translationsValue[this.selectedStatus]
    // const confirmMessage = `¿Confirmas cambiar ${this.selectedPackageIds.length} paquete(s) a "${statusLabel}"?`

    // if (!confirm(confirmMessage)) {
    //   return
    // }

    // Show loading
    this.applyBtnTarget.disabled = true
    this.applyBtnTarget.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Procesando...
    `

    try {
      const response = await fetch('/admin/packages/bulk_status_change', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          package_ids: this.selectedPackageIds,
          new_status: this.selectedStatus,
          reason: 'Cambio masivo desde admin'
        })
      })

      if (response.ok) {
        this.applyBtnTarget.innerHTML = `
          <svg class="h-5 w-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
          </svg>
          Éxito
        `
        setTimeout(() => window.location.reload(), 500)
      } else {
        const data = await response.json()
        throw new Error(data.error || 'Error al cambiar estados')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Error: ' + error.message)
      this.applyBtnTarget.disabled = false
      this.applyBtnTarget.textContent = 'Aplicar cambio'
    }
  }

  generateLabels() {
    const selectedIds = this.getSelectedIds()

    if (selectedIds.length === 0) {
      alert('Selecciona al menos un paquete')
      return
    }

    // Crear un formulario temporal solo con los package_ids seleccionados
    const tempForm = document.createElement('form')
    tempForm.method = 'POST'
    tempForm.action = '/admin/packages/generate_labels'
    tempForm.target = '_blank' // Abrir PDF en nueva pestaña

    // CSRF token
    const csrfToken = document.querySelector('[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    tempForm.appendChild(csrfInput)

    // Agregar solo los package_ids seleccionados
    selectedIds.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'package_ids[]'
      input.value = id
      tempForm.appendChild(input)
    })

    // Submit el formulario temporal
    document.body.appendChild(tempForm)
    tempForm.submit()
    document.body.removeChild(tempForm)
  }

  async assignDriver(event) {
    const select = event.target
    const packageId = select.dataset.packageId
    const courierId = select.value
    const assignUrl = select.dataset.assignUrl
    const csrfToken = select.dataset.csrfToken
    const originalValue = select.dataset.originalValue || ''

    select.disabled = true
    select.style.opacity = '0.5'

    try {
      const response = await fetch(assignUrl, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ courier_id: courierId })
      })

      if (response.ok) {
        window.location.reload()
      } else {
        // Obtener el mensaje de error del servidor
        const data = await response.json()
        const errorMessage = data.errors ? data.errors.join(', ') : 'Error al asignar conductor'
        throw new Error(errorMessage)
      }
    } catch (error) {
      console.error('Error:', error)
      // Mostrar el mensaje de error específico del servidor
      alert(error.message)

      // IMPORTANTE: Resetear el select a "Sin asignar"
      select.value = ''
      select.disabled = false
      select.style.opacity = '1'
    }
  }
}
