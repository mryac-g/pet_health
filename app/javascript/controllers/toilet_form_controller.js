import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["kindInput", "conditionSection"]

  connect() {
    this.toggle()
  }

  toggle() {
    this.conditionSectionTarget.hidden = this.kindInputTarget.value !== "poop"
  }
}
