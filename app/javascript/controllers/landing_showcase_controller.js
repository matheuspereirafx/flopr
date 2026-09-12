import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "indicator", "previous", "next"]

  connect() {
    this.currentIndex = 0
    this.isLocked = false
    this.autoplayTimer = window.setInterval(() => this.advanceAutomatically(), 5000)
    this.update()
  }

  disconnect() {
    window.clearInterval(this.autoplayTimer)
  }

  next(event) {
    event?.preventDefault()
    this.changeTo(this.currentIndex + 1)
  }

  previous(event) {
    event?.preventDefault()
    this.changeTo(this.currentIndex - 1)
  }

  advanceAutomatically() {
    if (this.isLocked) return

    const nextIndex = this.currentIndex === this.cardTargets.length - 1
      ? 0
      : this.currentIndex + 1

    this.changeTo(nextIndex)
  }

  changeTo(index) {
    if (index < 0 || index >= this.cardTargets.length || index === this.currentIndex || this.isLocked) return

    this.isLocked = true
    this.element.classList.add("is-loop-active")
    this.currentIndex = index
    this.update()
    window.setTimeout(() => { this.isLocked = false }, 600)
  }

  update() {
    this.cardTargets.forEach((card, index) => {
      card.classList.toggle("is-active", index === this.currentIndex)
      card.setAttribute("aria-hidden", index !== this.currentIndex)
    })
    this.indicatorTargets.forEach((indicator, index) => indicator.classList.toggle("is-active", index === this.currentIndex))
    this.previousTarget.disabled = this.currentIndex === 0
    this.previousTarget.classList.toggle("landing-showcase__control--previous", this.currentIndex === 0)
    this.nextTarget.disabled = this.currentIndex === this.cardTargets.length - 1
  }
}
