import { Controller } from "@hotwired/stimulus"

// サマリー画面で、まとめ文章とグラフの両方/どちらか一方だけを表示切り替え
// できるようにする。画面表示のみに影響する。PDF・印刷はGrover(Puppeteer)が
// このページを最初から独立して読み込んで生成するため、ここでの切り替え
// 状態の影響は受けず、常に両方が出力される
export default class extends Controller {
  static targets = ["text", "graph", "button"]

  showText() {
    this.#toggle(true, false, "text")
  }

  showGraph() {
    this.#toggle(false, true, "graph")
  }

  showBoth() {
    this.#toggle(true, true, "both")
  }

  #toggle(showText, showGraph, mode) {
    this.textTarget.classList.toggle("hidden", !showText)
    this.graphTarget.classList.toggle("hidden", !showGraph)
    this.buttonTargets.forEach((button) => {
      button.classList.toggle("btn-active", button.dataset.mode === mode)
    })
  }
}
