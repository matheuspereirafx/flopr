import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["positions", "template", "row", "positionLabel", "positionInput", "destroyInput", "total", "totalValue", "totalMessage", "submit"]

  connect() { this.renumber(); this.updateTotal() }

  addPosition() {
    this.positionsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now()))
    this.renumber()
    this.updateTotal()
  }

  removePosition(event) {
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
    const total = this.rowTargets.reduce((sum, row) => {
      if (row.hidden) return sum
      return sum + (parseFloat(row.querySelector("input[name*='[percentage]']")?.value) || 0)
    }, 0)
    const formattedTotal = total.toFixed(2).replace(/\.00$/, "")
    this.totalValueTarget.textContent = `${formattedTotal} %`

    if (total > 100) {
      this.totalTarget.dataset.state = "exceeded"
      this.totalMessageTarget.textContent = "A soma dos percentuais não pode ultrapassar 100%."
    } else if (total === 100) {
      this.totalTarget.dataset.state = "complete"
      this.totalMessageTarget.textContent = "Distribuição completa."
    } else {
      this.totalTarget.dataset.state = "incomplete"
      this.totalMessageTarget.textContent = `Faltam ${(100 - total).toFixed(2).replace(/\.00$/, "")} % para completar a distribuição.`
    }

    this.submitTarget.disabled = total !== 100
  }
}
