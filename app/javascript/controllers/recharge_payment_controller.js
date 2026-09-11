import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "feeToggle", "feeDetails", "includeFeeValue", "total"]
  static values = { amount: Number, chips: Number }

  open() {
    this.overlayTarget.hidden = false
    this.updateTotal()
  }

  close() {
    this.overlayTarget.hidden = true
  }

  async copyPixKey() {
    if (!this.hasPixKeyTarget) return

    await navigator.clipboard.writeText(this.pixKeyTarget.textContent.trim())
  }

  toggleFee() {
    if (this.hasFeeDetailsTarget) this.feeDetailsTarget.hidden = !this.feeToggleTarget.checked
    this.updateTotal()
  }

  updateTotal() {
    const feeSelected = this.feeToggleTarget?.checked || false
    if (this.hasFeeDetailsTarget) this.feeDetailsTarget.hidden = !feeSelected
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
