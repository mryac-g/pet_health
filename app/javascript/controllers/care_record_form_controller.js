import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "section"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selected = this.typeSelectTarget.value

    this.sectionTargets.forEach((section) => {
      section.hidden = section.dataset.recordType !== selected
    })
  }
}
