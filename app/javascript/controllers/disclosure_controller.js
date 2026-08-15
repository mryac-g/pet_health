import { Controller } from "@hotwired/stimulus"

// 「入力する」ボタンをクリックするまで隠しておきたい任意項目(通院のワクチン等)向けの
// 汎用トグル。ボタンを押すとボタン自身を隠し、中身の入力欄を表示する。
// 中の閉じるボタンから同じアクションを呼べば、ボタン表示に戻せる(元に戻れない問題への対応)
export default class extends Controller {
  static targets = ["trigger", "content"]

  toggle() {
    this.triggerTarget.classList.toggle("hidden")
    this.contentTarget.classList.toggle("hidden")
  }
}
