import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  async copy() {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(this.urlValue)
    } else {
      this.copyWithFallback()
    }

    this.element.title = "Link de convite copiado"
    this.element.setAttribute("aria-label", "Link de convite copiado")
    this.element.classList.add("is-copied")

    clearTimeout(this.copiedTimeout)
    this.copiedTimeout = setTimeout(() => {
      this.element.classList.remove("is-copied")
    }, 2200)
  }

  copyWithFallback() {
    const input = document.createElement("textarea")
    input.value = this.urlValue
    input.setAttribute("readonly", "")
    input.style.position = "fixed"
    input.style.opacity = "0"
    document.body.append(input)
    input.select()
    document.execCommand("copy")
    input.remove()
  }
}
