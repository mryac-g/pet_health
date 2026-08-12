import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "frame"]

  open(event) {
    event.preventDefault()
    this.frameTarget.src = event.currentTarget.href
    this.dialogTarget.showModal()
  }

  close(event) {
    event?.preventDefault()
    this.dialogTarget.close()
  }
}
