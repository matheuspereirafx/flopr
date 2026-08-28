import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "trigger"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) this.open()
  }

  open() {
    this.overlayTarget.hidden = false
    this.triggerTarget?.setAttribute("aria-expanded", "true")
  }

  close() {
    this.overlayTarget.hidden = true
    this.triggerTarget?.setAttribute("aria-expanded", "false")
  }

}
