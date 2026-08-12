import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "option",
    "toggle",
    "fields",
    "moneyDisplay",
    "moneyValue",
    "chipsDisplay",
    "chipsValue",
    "periodSelect"
  ]

  connect() {
    this.moneyDisplayTargets.forEach((input) => this.updateMoney(input))
    this.chipsDisplayTargets.forEach((input) => this.updateChips(input))
    this.optionTargets.forEach((option) => this.syncOption(option))
    this.syncPeriodOptions()
  }

  toggle(event) {
    const toggle = event.currentTarget
    const option = event.currentTarget.closest("[data-financial-options-target='option']")

    if (!toggle.checked && this.hasConfiguredValues(option)) {
      const confirmed = window.confirm(
        "Esta configuração deixará de ser utilizada pelos jogadores. Deseja continuar?"
      )

      if (!confirmed) {
        toggle.checked = true
        return
      }
    }

    this.syncOption(option)
    this.syncDoubleRebuy()
  }

  changePeriod() {
    this.syncPeriodOptions()
  }

  formatMoney(event) {
    this.updateMoney(event.currentTarget)
  }

  formatChips(event) {
    this.updateChips(event.currentTarget)
  }

  updateMoney(input) {
    const hiddenInput = input.closest("[data-financial-money]").querySelector(
      "[data-financial-options-target='moneyValue']"
    )
    const digits = input.value.replace(/\D/g, "")

    if (digits === "") {
      hiddenInput.value = ""
      return
    }

    const amount = Number.parseInt(digits, 10) / 100
    input.value = new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL"
    }).format(amount)
    hiddenInput.value = amount.toFixed(2)
  }

  updateChips(input) {
    const hiddenInput = input.closest("[data-financial-chips]").querySelector(
      "[data-financial-options-target='chipsValue']"
    )
    const digits = input.value.replace(/\D/g, "")

    if (digits === "") {
      hiddenInput.value = ""
      return
    }

    const chips = Number.parseInt(digits, 10)
    input.value = new Intl.NumberFormat("pt-BR").format(chips)
    hiddenInput.value = chips.toString()
  }

  syncOption(option) {
    const toggle = option.querySelector("[data-financial-options-target='toggle']")
    if (!toggle) return

    const fields = option.querySelector("[data-financial-options-target='fields']")
    const active = toggle.checked

    option.classList.toggle("financial-option--active", active)
    fields.hidden = !active
    fields.querySelectorAll("input").forEach((input) => {
      input.disabled = !active && input.type !== "hidden"
    })
  }

  syncDoubleRebuy() {
    const rebuy = this.optionTargets.find((option) => option.dataset.kind === "rebuy")
    const doubleRebuy = this.optionTargets.find((option) => option.dataset.kind === "double_rebuy")
    if (!rebuy || !doubleRebuy) return

    const doubleToggle = doubleRebuy.querySelector("[data-financial-options-target='toggle']")
    if (!doubleToggle) return

    const rebuyIsActive = rebuy.classList.contains("financial-option--active")
    doubleToggle.disabled = !this.periodSelected || !rebuyIsActive

    if (!rebuyIsActive) {
      doubleToggle.checked = false
      this.syncOption(doubleRebuy)
    }
  }

  syncPeriodOptions() {
    this.toggleTargets.forEach((toggle) => {
      const option = toggle.closest("[data-financial-options-target='option']")

      if (option.dataset.kind === "double_rebuy") return

      toggle.disabled = !this.periodSelected

      if (!this.periodSelected) {
        toggle.checked = false
        this.syncOption(option)
      }
    })

    this.syncDoubleRebuy()
  }

  get periodSelected() {
    return this.periodSelectTarget.value !== ""
  }

  hasConfiguredValues(option) {
    return Array.from(
      option.querySelectorAll(
        "[data-financial-options-target='moneyValue'], [data-financial-options-target='chipsValue'], input[type='text']"
      )
    ).some((input) => input.value.trim() !== "")
  }
}
