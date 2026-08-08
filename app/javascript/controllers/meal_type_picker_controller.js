import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display"]

  select(event) {
    this.inputTarget.value = event.params.name
    this.updateDisplay()
  }

  updateDisplay() {
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = this.inputTarget.value || "単位"
    }
  }
}
