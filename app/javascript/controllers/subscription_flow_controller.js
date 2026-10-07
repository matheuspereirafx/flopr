import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "club",
    "downgradeWarning",
    "downgradeDialog",
    "downgradeForm",
    "downgradeClub",
    "downgradeCurrentPlan",
    "downgradeEffectiveAt",
    "quotePanel",
    "quoteCurrentPlan",
    "quoteNewPlan",
    "quoteCredit",
    "quoteAmount",
    "quoteRenewal",
    "quoteMessage",
    "submit"
  ]
  static values = { newPlanPrice: Number, newPlanId: Number, quoteUrl: String }

  connect() {
    this.quoteRequest = null
    this.quoteState = "idle"
    this.checkDowngrade()
  }

  changeClub() {
    this.checkDowngrade()
    this.loadQuote()
  }

  loadQuote() {
    const clubId = this.clubTarget.value
    if (!clubId) {
      this.quoteState = "idle"
      this.quotePanelTarget.hidden = true
      return
    }

    this.quoteRequest?.abort()
    this.quoteRequest = new AbortController()
    this.quoteState = "loading"
    this.quotePanelTarget.hidden = false
    this.quoteMessageTarget.textContent = "Calculando valor proporcional..."
    this.submitTarget.disabled = true

    const params = new URLSearchParams({ club_id: clubId, plan_id: this.newPlanIdValue })
    fetch(`${this.quoteUrlValue}?${params}`, {
      headers: { Accept: "application/json" },
      credentials: "same-origin",
      signal: this.quoteRequest.signal
    })
      .then((response) => response.ok ? response.json() : response.json().then((body) => Promise.reject(body)))
      .then((quote) => this.applyQuote(quote))
      .catch((error) => {
        if (error.name === "AbortError") return

        this.quoteState = "error"
        this.quoteMessageTarget.textContent = error.message || "Não foi possível calcular a contratação."
      })
  }

  applyQuote(quote) {
    this.quoteState = quote.eligible ? "ready" : quote.mode
    this.quoteCurrentPlanTarget.textContent = quote.current_plan_name || "Nenhum plano pago"
    this.quoteNewPlanTarget.textContent = quote.new_plan_name
    this.quoteCreditTarget.textContent = this.formatCurrency(quote.credit_amount)
    this.quoteAmountTarget.textContent = this.formatCurrency(quote.amount_due)
    this.quoteRenewalTarget.textContent = this.formatDate(quote.next_renewal_at)
    this.quoteMessageTarget.textContent = quote.message || ""
    this.submitTarget.disabled = !quote.eligible && quote.mode !== "downgrade"
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
    if (["loading", "error", "incompatible_cycle", "same_plan"].includes(this.quoteState)) {
      event.preventDefault()
      return
    }

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

  formatCurrency(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(value) || 0)
  }

  formatDate(value) {
    if (!value) return "Não definida"

    return new Intl.DateTimeFormat("pt-BR").format(new Date(value))
  }
}
