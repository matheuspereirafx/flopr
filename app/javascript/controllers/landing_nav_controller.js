import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScrollY = window.scrollY
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    const currentScrollY = window.scrollY

    if (currentScrollY <= 0) {
      this.element.classList.remove("is-hidden")
    } else if (currentScrollY > this.lastScrollY) {
      this.element.classList.add("is-hidden")
    } else if (currentScrollY < this.lastScrollY) {
      this.element.classList.remove("is-hidden")
    }

    this.lastScrollY = currentScrollY
  }
}
