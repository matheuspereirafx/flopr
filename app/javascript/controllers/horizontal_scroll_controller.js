import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "container",
    "previousButton",
    "nextButton"
  ]

  connect() {
    this.updateButtons()

    this.resizeObserver = new ResizeObserver(() => {
      this.updateButtons()
    })

    this.resizeObserver.observe(this.containerTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  next() {
    this.containerTarget.scrollBy({
      left: this.scrollDistance,
      behavior: "smooth"
    })
  }

  previous() {
    this.containerTarget.scrollBy({
      left: -this.scrollDistance,
      behavior: "smooth"
    })
  }

  updateButtons() {
    const container = this.containerTarget

    const maximumScroll =
      container.scrollWidth - container.clientWidth

    const currentScroll = container.scrollLeft

    this.previousButtonTarget.disabled =
      currentScroll <= 2

    this.nextButtonTarget.disabled =
      currentScroll >= maximumScroll - 2
  }

  get scrollDistance() {
    const firstCard =
      this.containerTarget.querySelector(".tournament-card")

    if (!firstCard) {
      return this.containerTarget.clientWidth
    }

    const containerStyles =
      window.getComputedStyle(this.containerTarget)

    const gap =
      parseFloat(containerStyles.columnGap) ||
      parseFloat(containerStyles.gap) ||
      0

    return firstCard.getBoundingClientRect().width + gap
  }
}
