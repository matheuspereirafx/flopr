import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "dropdown"]

  toggle() {
    const isOpen = !this.dropdownTarget.hidden

    this.dropdownTarget.hidden = isOpen
    this.buttonTarget.setAttribute("aria-expanded", (!isOpen).toString())
  }

  closeOutside(event) {
    if (this.element.contains(event.target)) return

    this.close()
  }

  close() {
    this.dropdownTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
