import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "button"]

  toggle(event) {
    event.stopPropagation()

    const isClosed = this.dropdownTarget.hidden

    this.dropdownTarget.hidden = !isClosed
    this.buttonTarget.setAttribute("aria-expanded", String(isClosed))
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  close() {
    this.dropdownTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
