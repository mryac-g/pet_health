import { Controller } from "@hotwired/stimulus"

// datetime-local/date系inputは、素のままだとカレンダーアイコンをクリックした時だけ
// ピッカーが開き、入力欄の他の部分をクリックしてもキャレットが立つだけで開かない。
// 入力欄内のどこをクリックしても開くようにする(showPicker未対応ブラウザでは何もしない)
export default class extends Controller {
  open() {
    if (typeof this.element.showPicker === "function") {
      this.element.showPicker()
    }
  }
}
