import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autocomplete"
// Generic autocomplete component for any list of items
export default class extends Controller {
  static targets = ["input", "hiddenField", "results", "list"]
  static values = {
    items: Array  // [{id: 1, name: "Item Name"}, ...]
  }

  connect() {
    // Close dropdown when clicking outside
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.boundHandleClickOutside)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleClickOutside)
  }

  // Filter items as user types
  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()

    // If query is empty, hide results
    if (query.length === 0) {
      this.hideResults()
      this.clearSelection()
      return
    }

    // Filter items
    const matches = this.itemsValue.filter(item =>
      item.name.toLowerCase().includes(query)
    )

    // Display results
    this.displayResults(matches)
  }

  // Display filtered results
  displayResults(items) {
    if (items.length === 0) {
      this.listTarget.innerHTML = '<li class="px-4 py-2 text-sm text-gray-500">No se encontraron resultados</li>'
      this.showResults()
      return
    }

    this.listTarget.innerHTML = items.map(item => `
      <li class="px-4 py-2 text-sm text-gray-700 hover:bg-indigo-50 cursor-pointer transition-colors"
          data-action="click->autocomplete#select"
          data-item-id="${item.id}"
          data-item-name="${item.name}">
        ${this.highlightMatch(item.name, this.inputTarget.value)}
      </li>
    `).join('')

    this.showResults()
  }

  // Highlight matching text
  highlightMatch(text, query) {
    if (!query) return text

    const regex = new RegExp(`(${this.escapeRegex(query)})`, 'gi')
    return text.replace(regex, '<span class="font-semibold text-indigo-600">$1</span>')
  }

  // Escape special regex characters
  escapeRegex(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  }

  // Select an item from the list
  select(event) {
    const element = event.currentTarget
    const itemId = element.dataset.itemId
    const itemName = element.dataset.itemName

    // Update input and hidden field
    this.inputTarget.value = itemName
    this.hiddenFieldTarget.value = itemId

    // Hide results
    this.hideResults()
  }

  // Clear selection
  clearSelection() {
    this.hiddenFieldTarget.value = ''
  }

  // Show results dropdown
  showResults() {
    this.resultsTarget.classList.remove('hidden')
  }

  // Hide results dropdown
  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }

  // Handle clicks outside the component
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // Handle focus on input - show results if there are matches
  handleFocus() {
    if (this.inputTarget.value.trim().length > 0) {
      this.filter()
    }
  }
}
