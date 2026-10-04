import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["positions", "template", "row", "positionLabel", "positionInput", "destroyInput", "total", "totalValue", "totalMessage", "submit"]
  static values = { netAmount: Number }

  connect() { this.renumber(); this.updateTotal() }

  addPosition() {
    const remaining = 100 - this.currentTotal()
    if (remaining <= 0) return

    this.positionsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now()))
    const row = this.rowTargets.at(-1)
    row.querySelector("input[name*='[percentage]']").value = remaining
    this.renumber()
    this.updateTotal()
  }

  removePosition(event) {
    if (this.visibleRows().length <= 1) return

    const row = event.target.closest("[data-prize-pool-form-target='row']")
    const destroy = row.querySelector("[data-prize-pool-form-target='destroyInput']")
    if (destroy) { destroy.value = "1"; row.hidden = true } else { row.remove() }
    this.renumber(); this.updateTotal()
  }

  renumber() {
    let position = 0
    this.rowTargets.forEach((row) => {
      if (row.hidden) return
      position += 1
      row.querySelector("[data-prize-pool-form-target='positionLabel']").textContent = `${position}º lugar`
      row.querySelector("[data-prize-pool-form-target='positionInput']").value = position
    })
  }

  updateTotal() {
    const rows = this.visibleRows()
    const total = this.currentTotal()
    const hasInvalidPercentage = rows.some((row) => {
      const value = row.querySelector("input[name*='[percentage]']")?.value
      return value === "" || !/^\d+$/.test(value) || Number(value) <= 0 || Number(value) > 100
    })
    const formattedTotal = total.toString()
    this.totalValueTarget.textContent = `${formattedTotal} %`
    this.updateAmounts(rows)

    if (hasInvalidPercentage || total > 100) {
      this.totalTarget.dataset.state = "exceeded"
      this.totalMessageTarget.textContent = "Informe percentuais inteiros maiores que zero, totalizando no máximo 100%."
    } else if (rows.length === 0) {
      this.totalTarget.dataset.state = "incomplete"
      this.totalMessageTarget.textContent = "Configure pelo menos uma posição."
    } else if (total === 100) {
      this.totalTarget.dataset.state = "complete"
      this.totalMessageTarget.textContent = "Distribuição completa."
    } else {
      this.totalTarget.dataset.state = "incomplete"
      this.totalMessageTarget.textContent = `Faltam ${100 - total} % para completar a distribuição.`
    }

    this.submitTarget.disabled = hasInvalidPercentage || rows.length === 0 || total !== 100
  }

  visibleRows() {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  currentTotal() {
    return this.visibleRows().reduce((sum, row) => {
      return sum + (Number(row.querySelector("input[name*='[percentage]']")?.value) || 0)
    }, 0)
  }

  updateAmounts(rows) {
    let distributedCents = 0
    const netAmountCents = Math.round(this.netAmountValue * 100)

    rows.forEach((row, index) => {
      const percentage = Number(row.querySelector("input[name*='[percentage]']")?.value) || 0
      const amountCents = index === rows.length - 1
        ? netAmountCents - distributedCents
        : Math.round(netAmountCents * percentage / 100)
      distributedCents += amountCents
      const amount = row.querySelector("[data-prize-pool-form-target='amount']")
      if (amount) amount.textContent = this.formatCurrency(amountCents / 100)
    })
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
  }
}
