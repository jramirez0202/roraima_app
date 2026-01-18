import { Controller } from "@hotwired/stimulus"

// Sidebar Controller - Simplified for "floating card" layout
// The sidebar is always visible on desktop (md+) via CSS
// No toggle needed - layout is handled purely by CSS
export default class extends Controller {
  static targets = ["sidebar", "overlay", "main"]

  connect() {
    // Clean up any old localStorage state since we no longer use it
    localStorage.removeItem('sidebarClosed')
  }

  disconnect() {
    // Nothing to clean up
  }
}
