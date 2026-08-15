import { Controller } from "@hotwired/stimulus"

// 添付ファイルは選択した時点ではまだアップロードされていないため、ブラウザ上の
// FileListから画像はサムネイル、それ以外はファイル名を一覧表示してプレビューする
export default class extends Controller {
  static targets = ["input", "list"]

  render() {
    this.listTarget.querySelectorAll("img[data-object-url]").forEach((img) => {
      URL.revokeObjectURL(img.src)
    })
    this.listTarget.innerHTML = ""

    Array.from(this.inputTarget.files).forEach((file) => {
      this.listTarget.appendChild(this.buildItem(file))
    })
  }

  buildItem(file) {
    const li = document.createElement("li")
    li.className = "flex items-center gap-1 border border-base-300 rounded p-1 text-xs max-w-[10rem]"

    if (file.type.startsWith("image/")) {
      const img = document.createElement("img")
      img.src = URL.createObjectURL(file)
      img.dataset.objectUrl = "true"
      img.className = "w-8 h-8 object-cover rounded flex-shrink-0"
      li.appendChild(img)
    } else {
      const icon = document.createElement("span")
      icon.className = "flex-shrink-0"
      icon.textContent = file.type.startsWith("video/") ? "🎬" : "📄"
      li.appendChild(icon)
    }

    const name = document.createElement("span")
    name.className = "truncate"
    name.textContent = file.name
    li.appendChild(name)

    return li
  }
}
