import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "feeToggle", "includeFeeValue", "total"]
  static values = { amount: Number, chips: Number }

  open() {
    this.overlayTarget.hidden = false
    this.updateTotal()
  }

  close() {
    this.overlayTarget.hidden = true
  }

  toggleFee() {
    this.updateTotal()
  }

  updateTotal() {
    const feeSelected = this.feeToggleTarget?.checked || false
    const feeAmount = feeSelected ? this.feeToggleTarget.dataset.amount || 0 : 0
    const feeChips = feeSelected ? this.feeToggleTarget.dataset.chips || 0 : 0
    const totalAmount = Number(this.amountValue) + Number(feeAmount)
    const totalChips = Number(this.chipsValue) + Number(feeChips)

    this.totalTarget.textContent = `${this.formatCurrency(totalAmount)} · ${this.formatNumber(totalChips)} fichas`
    if (this.hasIncludeFeeValueTarget) this.includeFeeValueTarget.value = feeSelected ? "1" : "0"
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
  }

  formatNumber(value) {
    return new Intl.NumberFormat("pt-BR").format(value)
  }
}
