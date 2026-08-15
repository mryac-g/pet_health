import { Controller } from "@hotwired/stimulus"

// ネイティブのfile inputはファイル選択ダイアログを開くたびに選択内容を置き換えてしまい、
// 「もう1つ追加する」操作ができない。選んだファイルをコントローラー側で積み上げて保持し、
// input.filesへ都度書き戻すことで複数回に分けた選択を合算する。まだアップロードされていない
// ため、画像はサムネイル・それ以外はアイコンでプレビューし、個別に取り消せるようにする
export default class extends Controller {
  static targets = ["input", "list"]

  connect() {
    this.files = []
  }

  add() {
    this.files = this.files.concat(Array.from(this.inputTarget.files))
    this.sync()
  }

  remove(event) {
    const index = Number(event.params.index)
    this.files.splice(index, 1)
    this.sync()
  }

  sync() {
    const transfer = new DataTransfer()
    this.files.forEach((file) => transfer.items.add(file))
    this.inputTarget.files = transfer.files
    this.renderList()
  }

  renderList() {
    this.listTarget.querySelectorAll("img[data-object-url]").forEach((img) => {
      URL.revokeObjectURL(img.src)
    })
    this.listTarget.innerHTML = ""

    this.files.forEach((file, index) => {
      this.listTarget.appendChild(this.buildItem(file, index))
    })
  }

  buildItem(file, index) {
    const li = document.createElement("li")
    li.className = "relative flex flex-col items-center gap-1 border border-base-300 rounded-lg p-2 w-20"

    if (file.type.startsWith("image/")) {
      const img = document.createElement("img")
      img.src = URL.createObjectURL(file)
      img.dataset.objectUrl = "true"
      img.className = "w-16 h-16 object-cover rounded"
      li.appendChild(img)
    } else {
      const icon = document.createElement("span")
      icon.className = "w-16 h-16 flex items-center justify-center text-3xl bg-base-200 rounded"
      icon.textContent = file.type.startsWith("video/") ? "🎬" : "📄"
      li.appendChild(icon)
    }

    const name = document.createElement("span")
    name.className = "text-xs truncate w-full text-center"
    name.textContent = file.name
    li.appendChild(name)

    const removeButton = document.createElement("button")
    removeButton.type = "button"
    removeButton.className = "absolute -top-2 -right-2 w-5 h-5 flex items-center justify-center rounded-full bg-base-content text-base-100 text-xs leading-none"
    removeButton.setAttribute("aria-label", `${file.name}を取り消す`)
    removeButton.textContent = "×"
    removeButton.dataset.action = "attachment-preview#remove"
    removeButton.dataset.attachmentPreviewIndexParam = index
    li.appendChild(removeButton)

    return li
  }
}
