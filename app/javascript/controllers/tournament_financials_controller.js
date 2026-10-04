import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

export default class extends Controller {
  static targets = ["amount"]

  static values = {
    clubId: Number,
    tournamentId: Number
  }

  connect() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "TournamentFinancialsChannel",
        club_id: this.clubIdValue,
        tournament_id: this.tournamentIdValue
      },
      { received: (summary) => this.updateAmount(summary.net_amount) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  updateAmount(amount) {
    const value = Number(amount)
    if (!Number.isFinite(value)) return

    this.amountTarget.textContent = `R$ ${new Intl.NumberFormat("pt-BR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(value)}`
  }
}
