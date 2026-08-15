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
    li.className = "flex flex-col items-center gap-1 border border-base-300 rounded-lg p-2 w-20"

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

    return li
  }
}
