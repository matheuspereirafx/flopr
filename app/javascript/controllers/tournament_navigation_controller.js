import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.syncForViewport()
    this.boundSyncForViewport = this.syncForViewport.bind(this)
    window.addEventListener("resize", this.boundSyncForViewport)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundSyncForViewport)
  }

  expand() {
    if (this.mobileViewport()) return

    this.element.classList.remove("is-collapsed")
  }

  collapse() {
    if (this.mobileViewport()) return

    this.element.classList.add("is-collapsed")
  }

  mobileViewport() {
    return window.matchMedia("(max-width: 680px)").matches
  }

  syncForViewport() {
    const mobile = this.mobileViewport()

    if (!mobile) {
      this.menuTarget.hidden = false
      this.element.classList.add("is-collapsed")
    } else if (!this.menuTarget.dataset.initialized) {
      this.element.classList.remove("is-collapsed")
      this.menuTarget.hidden = false
      this.menuTarget.dataset.initialized = "true"
    }
  }
}
