import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "input"]

  update() {
    this.inputTargets.forEach((input) => {
      input.value = this.selectTarget.value
    })
  }
}
