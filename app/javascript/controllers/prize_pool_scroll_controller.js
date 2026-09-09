import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = null
    this.index = 0
    this.reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.start()
  }

  disconnect() {
    this.stop()
  }

  start() {
    if (this.reduceMotion || this.element.scrollHeight <= this.element.clientHeight) return

    this.timer = window.setInterval(() => this.scrollNext(), 3500)
  }

  stop() {
    if (this.timer) window.clearInterval(this.timer)
    this.timer = null
  }

  pause() {
    this.stop()
  }

  resume() {
    this.start()
  }

  scrollNext() {
    const cards = Array.from(this.element.children)
    if (cards.length < 4) return

    this.index += 1
    if (this.index > cards.length - 3) {
      this.index = 0
    }

    const nextCard = cards[this.index]
    this.element.scrollTo({ top: nextCard.offsetTop - this.element.offsetTop, behavior: "smooth" })
  }
}
