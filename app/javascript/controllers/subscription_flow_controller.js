import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["club", "downgradeWarning"]
  static values = { newPlanPrice: Number }

  connect() {
    this.checkDowngrade()
  }

  checkDowngrade() {
    const selectedOption = this.clubTarget.selectedOptions[0]
    const currentPlanPrice = Number(selectedOption?.dataset.currentPlanPrice)
    const isDowngrade = Number.isFinite(currentPlanPrice) && currentPlanPrice > this.newPlanPriceValue

    this.downgradeWarningTarget.hidden = !isDowngrade
    this.isDowngrade = isDowngrade
  }

  confirm(event) {
    this.checkDowngrade()
    if (!this.isDowngrade) return

    const confirmed = window.confirm(
      "Tem certeza que deseja reduzir o plano deste clube? Ele poderá perder acessos e funcionalidades."
    )

    if (!confirmed) event.preventDefault()
  }
}
