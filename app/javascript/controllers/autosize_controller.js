import { Controller } from "@hotwired/stimulus"

// メモ欄は入力した内容がスクロールなしで見えるよう、入力に合わせて高さを伸ばす。
// 10行を超えたら伸ばすのをやめ、テキストエリア自身のスクロールに任せる
const MAX_ROWS = 10

export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    const el = this.element
    const style = getComputedStyle(el)
    const lineHeight = parseFloat(style.lineHeight) || 20
    const verticalExtra =
      parseFloat(style.paddingTop) + parseFloat(style.paddingBottom) +
      parseFloat(style.borderTopWidth) + parseFloat(style.borderBottomWidth)
    const maxHeight = (lineHeight * MAX_ROWS) + verticalExtra

    el.style.height = "auto"
    const contentHeight = el.scrollHeight
    el.style.height = `${Math.min(contentHeight, maxHeight)}px`
    el.style.overflowY = contentHeight > maxHeight ? "auto" : "hidden"
  }
}
