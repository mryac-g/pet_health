import { Controller } from "@hotwired/stimulus"

// ファイル選択などの操作直後に、送信ボタンを別途押さなくてもフォームを自動送信する
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
