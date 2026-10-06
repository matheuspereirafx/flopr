import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "club",
    "downgradeWarning",
    "downgradeDialog",
    "downgradeForm",
    "downgradeClub",
    "downgradeCurrentPlan",
    "downgradeEffectiveAt"
  ]
  static values = { newPlanPrice: Number }

  connect() {
    this.checkDowngrade()
  }

  checkDowngrade() {
    const selectedOption = this.clubTarget.selectedOptions[0]
    const currentPlanPrice = Number(selectedOption?.dataset.currentPlanPrice)
    const isDowngrade = Boolean(selectedOption?.dataset.downgradePath) ||
      (Number.isFinite(currentPlanPrice) && currentPlanPrice > this.newPlanPriceValue)

    this.downgradeWarningTarget.hidden = !isDowngrade
    this.isDowngrade = isDowngrade
  }

  confirm(event) {
    const selectedOption = this.clubTarget.selectedOptions[0]
    const downgradePath = selectedOption?.dataset.downgradePath
    if (downgradePath) {
      event.preventDefault()
      this.downgradeFormTarget.action = downgradePath
      this.downgradeClubTarget.textContent = selectedOption.textContent.trim()
      this.downgradeCurrentPlanTarget.textContent = selectedOption.dataset.currentPlanName
      this.downgradeEffectiveAtTarget.textContent = selectedOption.dataset.currentPlanExpiresAt
      this.downgradeDialogTarget.showModal()
    }

    this.checkDowngrade()
    if (!this.isDowngrade) return
  }

  closeDowngradeConfirmation(event) {
    if (event.currentTarget === this.downgradeDialogTarget && event.target !== this.downgradeDialogTarget) return

    this.downgradeDialogTarget.close()
  }
}
