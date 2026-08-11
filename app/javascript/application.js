// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

// data-turbo-confirmのネイティブconfirm()を、レイアウトの#turbo-confirmダイアログに差し替える
Turbo.config.forms.confirm = (message) => {
  const dialog = document.getElementById("turbo-confirm")
  dialog.querySelector("p").textContent = message
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}
