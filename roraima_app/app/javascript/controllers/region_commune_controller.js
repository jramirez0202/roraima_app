import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="region-commune"
export default class extends Controller {
  static targets = ["region", "commune"]
  static values = {
    url: String,
    selectedCommune: Number
  }

  connect() {
    // Load communes if a region is already selected (edit mode)
    if (this.regionTarget.value) {
      this.loadCommunes(this.selectedCommuneValue)
    }
  }

  // Called when region select changes
  regionChanged() {
    this.loadCommunes()
  }

  loadCommunes(selectedCommuneId = null) {
    const regionId = this.regionTarget.value

    if (!regionId) {
      this.communeTarget.innerHTML = '<option value="">Primero seleccione región</option>'
      this.communeTarget.disabled = true
      return
    }

    // Disable and show loading
    this.communeTarget.disabled = true
    this.communeTarget.innerHTML = '<option>Cargando...</option>'

    // Fetch communes from API
    fetch(`${this.urlValue}/${regionId}`)
      .then(response => response.json())
      .then(communes => {
        this.communeTarget.innerHTML = '<option value="">Seleccione comuna</option>'

        communes.forEach(commune => {
          const option = document.createElement('option')
          option.value = commune.id
          option.text = commune.name

          if (selectedCommuneId && commune.id == selectedCommuneId) {
            option.selected = true
          }

          this.communeTarget.appendChild(option)
        })

        this.communeTarget.disabled = false
      })
      .catch(error => {
        console.error('Error loading communes:', error)
        this.communeTarget.innerHTML = '<option value="">Error al cargar</option>'
      })
  }
}
