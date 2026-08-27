import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "trigger", "selection", "pix", "card", "submit"]
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

  showSelection() {
    this.selectionTarget.hidden = false
    if (this.hasPixTarget) this.pixTarget.setAttribute("hidden", "hidden")
    if (this.hasCardTarget) this.cardTarget.setAttribute("hidden", "hidden")
  }

  submit(event) {
    this.submitTargets.forEach((button) => {
      button.disabled = true
    })
    event.submitter.textContent = "Aguarde..."
    this.close()
  }
}
