import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer"]

  static values = {
    seconds: Number,
    running: Boolean,
    overtime: Boolean
  }

  connect() {
    this.startedAt = Date.now()
    this.render()

    if (this.runningValue) {
      this.interval = window.setInterval(() => this.render(), 1000)
    }
  }

  disconnect() {
    window.clearInterval(this.interval)
  }

  render() {
    const elapsedSeconds = this.runningValue
      ? Math.floor((Date.now() - this.startedAt) / 1000)
      : 0
    const seconds = this.overtimeValue
      ? this.secondsValue + elapsedSeconds
      : Math.max(this.secondsValue - elapsedSeconds, 0)

    this.timerTarget.textContent = `${this.overtimeValue ? "+" : ""}${this.format(seconds)}`
  }

  format(seconds) {
    const minutes = Math.floor(seconds / 60).toString().padStart(2, "0")
    const remainder = (seconds % 60).toString().padStart(2, "0")

    return `${minutes}:${remainder}`
  }
}
