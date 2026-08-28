import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "card"]

  filter(event) {
    const selectedFilter = event.currentTarget.dataset.filter

    this.buttonTargets.forEach((button) => {
      button.classList.toggle(
        "club-events__filter--active",
        button === event.currentTarget
      )
    })

    this.cardTargets.forEach((card) => {
      card.hidden = !this.matchesFilter(card, selectedFilter)
    })
  }

  matchesFilter(card, selectedFilter) {
    if (selectedFilter === "live") {
      return ["running", "paused", "overtime"].includes(card.dataset.clockStatus) &&
        card.dataset.tournamentStatus === "posted"
    }

    if (selectedFilter === "upcoming") {
      return card.dataset.tournamentStatus === "posted" &&
        new Date(card.dataset.startsAt) >= new Date()
    }

    return true
  }
}
