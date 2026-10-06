import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "plan", "futurePlan"]

  openConfirmation() {
    const selectedPlan = this.planTargets.find((plan) => plan.checked)
    if (!selectedPlan) return

    this.futurePlanTarget.textContent = selectedPlan.dataset.planName
    this.dialogTarget.showModal()
  }

  closeConfirmation() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.closeConfirmation()
  }

  selectPlan(event) {
    this.futurePlanTarget.textContent = event.currentTarget.dataset.planName
  }
}
