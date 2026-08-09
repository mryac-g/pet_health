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

  // モーダル内でプリセットの追加・削除が行われていた場合のみ、記録フォームの
  // ボタン一覧を最新化するためページを再取得する(成功メッセージの有無で判定)
  refreshIfChanged() {
    if (this.frameTarget.querySelector(".alert-success")) {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
