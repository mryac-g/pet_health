import { Controller } from "@hotwired/stimulus"

// サマリー画面の「編集する」ボタンから戻ってきたとき、直前まで見ていた記録の
// 位置までスクロールする。URLフラグメント(#id)はTurboのfetchベースの
// リダイレクト追跡で失われてしまうため、クエリパラメータ経由で渡している
export default class extends Controller {
  static values = { target: String }

  connect() {
    if (!this.targetValue) return

    document.getElementById(this.targetValue)?.scrollIntoView({ block: "center" })
  }
}
