import { Controller } from "@hotwired/stimulus"

// トースト化(issue #158)によりメッセージが常時ページ上に浮いたままになるため、
// 一定時間で自動的に消す
export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.timeout = setTimeout(() => this.element.remove(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
