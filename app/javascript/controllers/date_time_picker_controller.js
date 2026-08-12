import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const input = event.currentTarget

    if (typeof input.showPicker === "function") {
      input.showPicker()
    }
  }
}
