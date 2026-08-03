import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const original = this.buttonTarget.textContent

    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.buttonTarget.textContent = "コピーしました"
    } catch (error) {
      this.buttonTarget.textContent = "コピーできませんでした"
    }

    setTimeout(() => {
      this.buttonTarget.textContent = original
    }, 2000)
  }
}
