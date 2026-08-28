import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "options", "option", "transaction", "empty"]

  connect() {
    this.onDocumentClick = this.closeWhenClickOutside.bind(this)
    document.addEventListener("click", this.onDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
  }

  showOptions() {
    this.optionsTarget.hidden = false
  }

  filter() {
    const query = this.normalizedQuery()

    this.optionTargets.forEach((option) => {
      option.hidden = query.length > 0 && !option.dataset.search.includes(query)
    })

    this.optionsTarget.hidden = false
    this.filterTransactions(query)
  }

  select(event) {
    this.inputTarget.value = event.currentTarget.dataset.label
    this.optionsTarget.hidden = true
    this.filterTransactions(this.normalizedQuery())
  }

  closeWhenClickOutside(event) {
    if (this.element.contains(event.target)) return

    this.optionsTarget.hidden = true
  }

  normalizedQuery() {
    return this.inputTarget.value.trim().toLocaleLowerCase("pt-BR")
  }

  filterTransactions(query) {
    this.transactionTargets.forEach((transaction) => {
      transaction.hidden = query.length > 0 && !transaction.dataset.playerSearch.includes(query)
    })

    this.emptyTarget.hidden = this.transactionTargets.some((transaction) => !transaction.hidden)
  }
}
