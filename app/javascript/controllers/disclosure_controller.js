import { Controller } from "@hotwired/stimulus"

// 「入力する」ボタンをクリックするまで隠しておきたい任意項目(通院のワクチン等)向けの
// 汎用トグル。ボタンを押すとボタン自身を隠し、中身の入力欄を表示する
export default class extends Controller {
  static targets = ["trigger", "content"]

  toggle() {
    this.triggerTarget.classList.add("hidden")
    this.contentTarget.classList.remove("hidden")
  }
}
