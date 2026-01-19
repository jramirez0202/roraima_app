import { Controller } from "@hotwired/stimulus"

// Controlador para autocomplete de drivers con búsqueda lazy loading
// Reemplaza el dropdown tradicional que no escala con muchos drivers
export default class extends Controller {
  static targets = ["input", "dropdown", "hidden"]

  static values = {
    packageId: Number,
    assignUrl: String,
    currentDriverId: Number,
    currentDriverName: String
  }

  connect() {
    console.log('🔍 DriverAutocompleteController connected')
    this.selectedDriverId = this.currentDriverIdValue || null
    this.selectedDriverName = this.currentDriverNameValue || 'Sin asignar'
    this.searchTimeout = null
    this.isOpen = false

    // Cerrar dropdown al hacer click fuera
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener('click', this.closeOnClickOutside)

    // Reposicionar dropdown al hacer scroll (para que siga al input)
    this.repositionOnScroll = this.repositionOnScroll.bind(this)
    window.addEventListener('scroll', this.repositionOnScroll, true)
    window.addEventListener('resize', this.repositionOnScroll)
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnClickOutside)
    window.removeEventListener('scroll', this.repositionOnScroll, true)
    window.removeEventListener('resize', this.repositionOnScroll)
    if (this.searchTimeout) clearTimeout(this.searchTimeout)
  }

  // Reposicionar dropdown cuando se hace scroll o resize
  repositionOnScroll() {
    if (this.isOpen) {
      this.positionDropdown()
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  // Búsqueda con debounce
  search(event) {
    const query = event.target.value.trim()
    console.log('🔍 search() llamado, query:', `"${query}"`)

    // Si el query es muy corto, cerrar dropdown
    if (query.length < 2) {
      this.closeDropdown()
      return
    }

    // Limpiar timeout anterior
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    // Debounce de 300ms
    this.searchTimeout = setTimeout(() => {
      console.log('⏱️  Ejecutando búsqueda después de debounce')
      this.performSearch(query)
    }, 300)
  }

  // Realizar búsqueda al backend
  async performSearch(query) {
    try {
      const url = `/admin/drivers/search?q=${encodeURIComponent(query)}`
      console.log('🌐 Fetching:', url)

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      console.log('📥 Response status:', response.status)

      if (!response.ok) {
        throw new Error('Error al buscar drivers')
      }

      const drivers = await response.json()
      console.log('👥 Drivers recibidos:', drivers.length, drivers)

      this.renderResults(drivers)
      this.showDropdown()
    } catch (error) {
      console.error('❌ Error en búsqueda de drivers:', error)
      this.renderError()
    }
  }

  // Renderizar resultados en el dropdown
  renderResults(drivers) {
    console.log('📝 renderResults() llamado con', drivers.length, 'drivers')

    if (drivers.length === 0) {
      this.dropdownTarget.innerHTML = `
        <div class="px-3 py-2 text-xs text-gray-500 text-center italic">
          No se encontraron conductores
        </div>
      `
      console.log('⚠️  Sin resultados, mostrando mensaje')
      return
    }

    // Limitar a 8 resultados máximo
    const maxResults = 8
    const displayDrivers = drivers.slice(0, maxResults)
    const hasMore = drivers.length > maxResults

    // Dropdown simple - solo nombre del driver
    let html = displayDrivers.map(driver => `
      <div class="driver-result px-3 py-2 hover:bg-indigo-50 cursor-pointer text-xs text-gray-900 border-b border-gray-100 last:border-b-0"
           data-driver-id="${driver.id}"
           data-driver-name="${driver.name}"
           data-action="click->driver-autocomplete#selectDriver">
        ${driver.name}
      </div>
    `).join('')

    // Si hay más resultados, mostrar mensaje
    if (hasMore) {
      html += `
        <div class="px-3 py-2 text-xs text-gray-500 text-center italic bg-gray-50">
          +${drivers.length - maxResults} conductores más... Escribe para filtrar
        </div>
      `
    }

    this.dropdownTarget.innerHTML = html
  }

  // Renderizar mensaje de error
  renderError() {
    this.dropdownTarget.innerHTML = `
      <div class="px-4 py-3 text-sm text-red-600 text-center">
        Error al cargar conductores
      </div>
    `
  }

  // Seleccionar un driver
  async selectDriver(event) {
    const driverElement = event.currentTarget
    const driverId = parseInt(driverElement.dataset.driverId)
    const driverName = driverElement.dataset.driverName

    console.log(`Asignando driver ${driverName} (ID: ${driverId}) al paquete ${this.packageIdValue}`)

    // Cerrar dropdown
    this.closeDropdown()

    // Deshabilitar input mientras se procesa
    this.inputTarget.disabled = true
    this.inputTarget.value = 'Asignando...'

    try {
      const response = await fetch(this.assignUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ courier_id: driverId })
      })

      if (response.ok) {
        // Actualizar UI
        this.selectedDriverId = driverId
        this.selectedDriverName = driverName
        this.inputTarget.value = driverName
        this.inputTarget.disabled = false

        // Recargar página para reflejar cambios
        window.location.reload()
      } else {
        // Obtener mensaje de error del servidor
        const data = await response.json()
        const errorMessage = data.errors ? data.errors.join(', ') : 'Error al asignar conductor'
        throw new Error(errorMessage)
      }
    } catch (error) {
      console.error('Error al asignar driver:', error)
      alert(`Error: ${error.message}`)

      // Restaurar valor anterior
      this.inputTarget.value = this.selectedDriverName
      this.inputTarget.disabled = false
    }
  }

  // Desasignar driver (limpiar campo)
  async clearDriver(event) {
    event.stopPropagation()

    if (!confirm('¿Desasignar conductor del paquete?')) {
      return
    }

    console.log(`Desasignando driver del paquete ${this.packageIdValue}`)

    // Deshabilitar input mientras se procesa
    this.inputTarget.disabled = true
    this.inputTarget.value = 'Desasignando...'

    try {
      const response = await fetch(this.assignUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ courier_id: '' })
      })

      if (response.ok) {
        // Actualizar UI
        this.selectedDriverId = null
        this.selectedDriverName = 'Sin asignar'
        this.inputTarget.value = 'Sin asignar'
        this.inputTarget.disabled = false

        // Recargar página para reflejar cambios
        window.location.reload()
      } else {
        const data = await response.json()
        const errorMessage = data.errors ? data.errors.join(', ') : 'Error al desasignar conductor'
        throw new Error(errorMessage)
      }
    } catch (error) {
      console.error('Error al desasignar driver:', error)
      alert(`Error: ${error.message}`)

      // Restaurar valor anterior
      this.inputTarget.value = this.selectedDriverName
      this.inputTarget.disabled = false
    }
  }

  // Mostrar dropdown
  showDropdown() {
    console.log('👁️  showDropdown() llamado')
    console.log('   Dropdown target:', this.dropdownTarget)
    console.log('   Contenido HTML:', this.dropdownTarget.innerHTML.substring(0, 100))

    // Posicionar el dropdown usando fixed positioning para evitar problemas con overflow
    this.positionDropdown()

    this.dropdownTarget.classList.remove('hidden')
    this.isOpen = true
    console.log('✅ Dropdown mostrado (hidden removido)')
  }

  // Posicionar dropdown dinámicamente (hacia arriba o abajo según el espacio)
  positionDropdown() {
    const inputRect = this.inputTarget.getBoundingClientRect()
    const dropdownHeight = 240 // max-h-60 = 15rem = 240px
    const spaceBelow = window.innerHeight - inputRect.bottom
    const spaceAbove = inputRect.top

    // Si no hay espacio abajo, mostrar hacia arriba
    if (spaceBelow < dropdownHeight && spaceAbove > spaceBelow) {
      // Mostrar hacia arriba
      this.dropdownTarget.style.position = 'fixed'
      this.dropdownTarget.style.bottom = `${window.innerHeight - inputRect.top}px`
      this.dropdownTarget.style.top = 'auto'
      this.dropdownTarget.style.left = `${inputRect.left}px`
      this.dropdownTarget.style.width = `${inputRect.width}px`
    } else {
      // Mostrar hacia abajo (comportamiento normal)
      this.dropdownTarget.style.position = 'fixed'
      this.dropdownTarget.style.top = `${inputRect.bottom + 4}px`
      this.dropdownTarget.style.bottom = 'auto'
      this.dropdownTarget.style.left = `${inputRect.left}px`
      this.dropdownTarget.style.width = `${inputRect.width}px`
    }
  }

  // Cerrar dropdown
  closeDropdown() {
    console.log('🙈 closeDropdown() llamado')
    this.dropdownTarget.classList.add('hidden')
    this.isOpen = false
  }

  // Al hacer focus, limpiar si es "Sin asignar"
  async focusInput() {
    // Si está "Sin asignar", limpiar el campo para que el usuario empiece a escribir
    if (this.inputTarget.value === 'Sin asignar') {
      this.inputTarget.value = ''
    }
    // NO mostrar dropdown automáticamente - esperar que el usuario escriba
  }

  // Al perder focus, restaurar valor si está vacío
  blurInput() {
    // Delay para permitir click en dropdown
    setTimeout(() => {
      if (!this.isOpen && this.inputTarget.value.trim() === '') {
        this.inputTarget.value = this.selectedDriverName
      }
    }, 200)
  }
}
