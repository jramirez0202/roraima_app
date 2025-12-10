import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filters-panel"
export default class extends Controller {
  static targets = ["panel", "chevron", "communeSelect", "courierSelect", "trackingInput", "submitBtn"]
  static values = { expanded: Boolean }

  connect() {
    console.log('🔍 Filters Panel Controller connected')

    // Restore accordion state from localStorage
    const savedState = localStorage.getItem('filtersExpanded')
    if (savedState !== null) {
      this.expandedValue = savedState === 'true'
    }

    this.updatePanelState()
  }

  // Toggle accordion open/closed
  toggle(event) {
    event.preventDefault()
    this.expandedValue = !this.expandedValue
    this.updatePanelState()

    // Save state to localStorage
    localStorage.setItem('filtersExpanded', this.expandedValue)
  }

  // Update panel visibility and chevron rotation
  updatePanelState() {
    if (this.expandedValue) {
      this.panelTarget.classList.remove('hidden')
      this.chevronTarget.style.transform = 'rotate(180deg)'
    } else {
      this.panelTarget.classList.add('hidden')
      this.chevronTarget.style.transform = 'rotate(0deg)'
    }
  }

  // Optional: Auto-expand if filters are active
  expandedValueChanged() {
    this.updatePanelState()
  }
}
