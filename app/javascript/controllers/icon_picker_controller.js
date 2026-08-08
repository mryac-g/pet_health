import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "option"]

  connect() {
    this.refresh()
  }

  select(event) {
    this.inputTarget.value = event.params.value
    this.refresh()
  }

  refresh() {
    const selected = this.inputTarget.value

    this.optionTargets.forEach((option) => {
      option.classList.toggle("btn-active", option.dataset.iconPickerValueParam === selected)
    })
  }
}
