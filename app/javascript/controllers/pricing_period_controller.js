import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "card"]

  select(event) {
    const period = event.currentTarget.dataset.period

    this.toggleTargets.forEach((toggle) => {
      const active = toggle.dataset.period === period
      toggle.classList.toggle("is-active", active)
      toggle.setAttribute("aria-pressed", active.toString())
    })

    this.cardTargets.forEach((card) => this.updateCard(card, period))
  }

  updateCard(card, period) {
    const available = period === "monthly" || card.dataset.yearlyAvailable === "true"
    const prefix = period === "yearly" && !available ? "monthly" : period

    card.querySelector("h3").textContent = card.dataset[`${prefix}Name`]
    card.querySelector(".landing-plan__intro p").textContent = card.dataset[`${prefix}Description`]
    card.querySelector(".landing-plan__price").textContent = card.dataset[`${prefix}Price`]
    card.querySelector(".landing-plan__price-row small").textContent = `/ ${card.dataset[`${prefix}Period`]}`
    card.querySelector(".landing-plan__action").textContent = card.dataset[`${prefix}Action`]
    card.querySelector(".landing-plan__action").href = card.dataset[`${prefix}Path`]
  }
}
