import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "checkbox",
    "selectAll",
    "bulkStatusBtn",
    "bulkAssignBtn",
    "generateLabelsBtn",
    "modal",
    "selectedCount",
    "statusGrid",
    "applyBtn",
    "assignModal",
    "assignCount",
    "driverSearch",
    "driversDropdown",
    "assignPreview",
    "selectedDriverName",
    "currentAssigned",
    "newAssigned",
    "totalAssigned",
    "assignApplyBtn"
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
      this.bulkAssignBtnTarget.classList.remove('hidden')
      this.generateLabelsBtnTarget.classList.remove('hidden')
      this.bulkStatusBtnTarget.querySelector('span').textContent =
        `Cambiar Estado (${selectedCount} seleccionados)`
      this.bulkAssignBtnTarget.querySelector('span').textContent =
        `Asignar a Driver (${selectedCount})`
    } else {
      this.bulkStatusBtnTarget.classList.add('hidden')
      this.bulkAssignBtnTarget.classList.add('hidden')
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
    // Solo permitir cambios masivos a Bodega y Pendiente Retiro
    const statusKeys = ['pending_pickup', 'in_warehouse']
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
        const data = await response.json()

        // Verificar si hubo errores en el procesamiento
        if (data.failed > 0) {
          // Construir mensaje de error detallado
          let errorMessage = `${data.failed} de ${data.total} paquetes no pudieron cambiar de estado:\n\n`
          data.errors.forEach(err => {
            errorMessage += `• ${err.tracking_code}: ${err.error}\n`
          })

          if (data.successful > 0) {
            errorMessage += `\n✓ ${data.successful} paquetes cambiaron correctamente.`
          }

          alert(errorMessage)

          // Si hubo algunos exitosos, recargar para mostrar los cambios
          if (data.successful > 0) {
            setTimeout(() => window.location.reload(), 500)
          } else {
            // Si todos fallaron, restaurar el botón
            this.applyBtnTarget.disabled = false
            this.applyBtnTarget.textContent = 'Aplicar cambio'
          }
        } else {
          // Todo exitoso
          this.applyBtnTarget.innerHTML = `
            <svg class="h-5 w-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            Éxito
          `
          setTimeout(() => window.location.reload(), 500)
        }
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

  // ========================================
  // BULK ASSIGN DRIVER METHODS
  // ========================================

  openAssignModal() {
    const count = this.getSelectedCount()
    if (count === 0) {
      alert('Selecciona al menos un paquete')
      return
    }

    this.selectedPackageIds = this.getSelectedIds()
    this.assignCountTarget.textContent = count
    this.newAssignedTarget.textContent = count

    // Reset modal state
    this.selectedDriverId = null
    this.assignPreviewTarget.classList.add('hidden')
    this.assignApplyBtnTarget.disabled = true
    this.driverSearchTarget.value = ''
    this.closeDriversDropdown()

    this.assignModalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeAssignModal() {
    this.assignModalTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.selectedDriverId = null
    this.selectedPackageIds = []
    this.driverSearchTarget.value = ''
    this.closeDriversDropdown()
    this.assignPreviewTarget.classList.add('hidden')
    this.assignApplyBtnTarget.disabled = true
  }

  // Búsqueda de drivers con lazy loading (reutiliza el endpoint existente)
  searchDrivers(event) {
    const query = event.target.value.trim()

    // Si el query es muy corto, cerrar dropdown
    if (query.length < 2) {
      this.closeDriversDropdown()
      return
    }

    // Limpiar timeout anterior
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    // Debounce de 300ms
    this.searchTimeout = setTimeout(() => {
      this.performDriverSearch(query)
    }, 300)
  }

  // Realizar búsqueda al backend (reutiliza /admin/drivers/search)
  async performDriverSearch(query) {
    try {
      const url = `/admin/drivers/search?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error('Error al buscar drivers')
      }

      const drivers = await response.json()
      this.renderDriverResults(drivers)
      this.showDriversDropdown()
    } catch (error) {
      console.error('Error en búsqueda de drivers:', error)
      this.driversDropdownTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-red-600 text-center">
          Error al buscar conductores
        </div>
      `
    }
  }

  // Renderizar resultados de drivers (máximo 8)
  renderDriverResults(drivers) {
    if (drivers.length === 0) {
      this.driversDropdownTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500 text-center italic">
          No se encontraron conductores
        </div>
      `
      return
    }

    // Limitar a 8 resultados máximo
    const maxResults = 8
    const displayDrivers = drivers.slice(0, maxResults)
    const hasMore = drivers.length > maxResults

    let html = displayDrivers.map(driver => `
      <div class="driver-option px-4 py-3 hover:bg-green-50 cursor-pointer border-b border-gray-100 last:border-b-0"
           data-driver-id="${driver.id}"
           data-driver-name="${driver.name}"
           data-driver-assigned="${driver.assigned_count}"
           data-action="click->bulk-packages#selectDriverFromDropdown">
        <div class="flex items-center justify-between">
          <p class="text-sm font-medium text-gray-900">${driver.name}</p>
          <p class="text-xs text-gray-600">${driver.assigned_count} paquetes</p>
        </div>
      </div>
    `).join('')

    // Si hay más resultados, mostrar mensaje
    if (hasMore) {
      html += `
        <div class="px-4 py-2 text-xs text-gray-500 text-center italic bg-gray-50">
          +${drivers.length - maxResults} conductores más... Escribe para filtrar
        </div>
      `
    }

    this.driversDropdownTarget.innerHTML = html
  }

  showDriversDropdown() {
    this.driversDropdownTarget.classList.remove('hidden')
  }

  closeDriversDropdown() {
    this.driversDropdownTarget.classList.add('hidden')
  }

  clearSearch() {
    // Al hacer focus, limpiar el campo
    this.driverSearchTarget.value = ''
    this.closeDriversDropdown()
  }

  // Seleccionar driver desde el dropdown (nueva lógica)
  selectDriverFromDropdown(event) {
    const option = event.currentTarget
    this.selectedDriverId = option.dataset.driverId
    const driverName = option.dataset.driverName
    const currentAssigned = parseInt(option.dataset.driverAssigned)
    const newToAssign = this.selectedPackageIds.length
    const totalAssigned = currentAssigned + newToAssign

    // Cerrar dropdown y mostrar nombre seleccionado en el input
    this.closeDriversDropdown()
    this.driverSearchTarget.value = driverName

    // Update preview
    this.selectedDriverNameTarget.textContent = driverName
    this.currentAssignedTarget.textContent = currentAssigned
    this.newAssignedTarget.textContent = newToAssign
    this.totalAssignedTarget.textContent = totalAssigned

    // Show preview and enable button
    this.assignPreviewTarget.classList.remove('hidden')
    this.assignApplyBtnTarget.disabled = false
  }

  selectDriver(event) {
    const option = event.currentTarget
    this.selectedDriverId = option.dataset.driverId
    const driverName = option.dataset.driverName
    const currentAssigned = parseInt(option.dataset.driverAssigned)
    const newToAssign = this.selectedPackageIds.length
    const totalAssigned = currentAssigned + newToAssign

    // Update visual selection
    this.driversListTarget.querySelectorAll('.driver-option').forEach(opt => {
      opt.classList.remove('ring-2', 'ring-green-500', 'bg-green-50')
    })
    option.classList.add('ring-2', 'ring-green-500', 'bg-green-50')

    // Update preview
    this.selectedDriverNameTarget.textContent = driverName
    this.currentAssignedTarget.textContent = currentAssigned
    this.newAssignedTarget.textContent = newToAssign
    this.totalAssignedTarget.textContent = totalAssigned

    // Show preview and enable button
    this.assignPreviewTarget.classList.remove('hidden')
    this.assignApplyBtnTarget.disabled = false
  }

  async confirmAssignDriver() {
    if (!this.selectedDriverId || this.selectedPackageIds.length === 0) {
      alert('Debes seleccionar un conductor')
      return
    }

    // Show loading
    this.assignApplyBtnTarget.disabled = true
    this.assignApplyBtnTarget.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Asignando...
    `

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      const response = await fetch('/admin/packages/bulk_assign_driver', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          package_ids: this.selectedPackageIds,
          driver_id: this.selectedDriverId
        })
      })

      const data = await response.json()

      if (response.ok) {
        // Build clear and simple message
        let message = `📊 Asignación Masiva Completada\n\n`
        message += `Conductor: ${data.driver.name}\n`
        message += `Paquetes seleccionados: ${data.total}\n\n`

        // Successes
        if (data.successful > 0) {
          message += `✅ Asignados correctamente: ${data.successful} paquetes\n`
        }

        // Skipped - mensaje simple y claro
        if (data.skipped > 0) {
          message += `\n❌ NO se pudieron asignar ${data.skipped} paquetes por estado diferente a Bodega\n`

          // Show which statuses were found
          const wrongStatus = data.skipped_items.filter(item => item.reason === 'wrong_status')
          const alreadyAssigned = data.skipped_items.filter(item => item.reason === 'already_assigned')

          if (wrongStatus.length > 0) {
            message += `   → ${wrongStatus.length} no están en Bodega\n`
          }

          if (alreadyAssigned.length > 0) {
            message += `   → ${alreadyAssigned.length} ya tienen driver asignado\n`
          }
        }

        // Errors
        if (data.failed > 0) {
          message += `\n⚠️ Errores inesperados: ${data.failed}\n`
        }

        message += `\n📦 Total del conductor: ${data.driver.total_assigned} paquetes`

        // Show alert
        alert(message)

        // Reload to show updated data
        window.location.reload()
      } else {
        throw new Error(data.error || 'Error al asignar paquetes')
      }
    } catch (error) {
      console.error('Error:', error)
      alert(`❌ Error: ${error.message}`)

      // Restore button
      this.assignApplyBtnTarget.disabled = false
      this.assignApplyBtnTarget.innerHTML = 'Confirmar Asignación'
    }
  }
}
