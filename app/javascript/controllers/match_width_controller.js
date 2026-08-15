import { Controller } from "@hotwired/stimulus"

// CTAボタンの幅を、下の2ボタンの行の実測幅にJSで直接合わせる。
// flexboxの縮小フィット+幅100%の子要素という組み合わせはブラウザ間で
// 計算結果が割れることがあるため、確実に一致させるためJSで同期する
export default class extends Controller {
  static targets = ["row", "cta"]

  connect() {
    this.sync()
    this.resizeObserver = new ResizeObserver(() => this.sync())
    this.resizeObserver.observe(this.rowTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  sync() {
    this.ctaTarget.style.width = `${this.rowTarget.offsetWidth}px`
  }
}
