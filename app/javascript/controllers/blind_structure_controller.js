import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "body",
    "template",
    "row",
    "count",
    "duration",
    "durationInput",
    "durationLabel",
    "levelInput",
    "levelLabel",
    "destroyInput",
    "removeButton"
  ]

  connect() {
    this.synchronize()
  }

  changeCount() {
    const desiredCount = Number(this.countTarget.value)

    if (desiredCount < this.minimumLevels) {
      this.countTarget.value = this.minimumLevels
      return
    }

    if (desiredCount > this.visibleRows.length) {
      while (this.visibleRows.length < desiredCount) {
        this.addRow()
      }
    }

    if (desiredCount < this.visibleRows.length) {
      const rowsToRemove = this.visibleRows.slice(desiredCount)

      if (rowsToRemove.some((row) => this.rowHasValues(row))) {
        const confirmed = window.confirm(
          "Os últimos níveis possuem valores preenchidos. Deseja removê-los?"
        )

        if (!confirmed) {
          this.countTarget.value = this.visibleRows.length
          return
        }
      }

      rowsToRemove.forEach((row) => this.markForRemoval(row))
    }

    this.synchronize()
  }

  add() {
    this.addRow()
    this.synchronize()
  }

  remove(event) {
    if (this.visibleRows.length <= this.minimumLevels) return

    const row = event.currentTarget.closest("tr")

    if (this.rowHasValues(row)) {
      const confirmed = window.confirm(
        "Este nível possui valores preenchidos. Deseja excluí-lo?"
      )

      if (!confirmed) return
    }

    this.markForRemoval(row)
    this.synchronize()
  }

  changeDuration() {
    const newDuration = this.durationTarget.value

    if (this.durationInputs.every((input) => input.value === newDuration)) {
      return
    }

    const confirmed = window.confirm(
      `Aplicar a duração de ${newDuration} minutos em todos os níveis?`
    )

    if (!confirmed) {
      this.durationTarget.value =
        this.durationInputs[0]?.value || 15

      return
    }

    this.durationInputs.forEach((input) => {
      input.value = newDuration
    })

    this.durationLabelTargets.forEach((label) => {
      label.textContent = `${newDuration} min`
    })
  }

  suggestBigBlind(event) {
    const row = event.currentTarget.closest("tr")
    const smallBlind = Number(event.currentTarget.value)
    const bigBlind = row.querySelector(
      '[data-blind-structure-target="bigBlind"]'
    )

    if (Number.isNaN(smallBlind) || smallBlind <= 0) return

    bigBlind.value = smallBlind * 2
  }

  addRow() {
    const uniqueIndex = Date.now().toString()
    const rowHtml = this.templateTarget.innerHTML.replaceAll(
      "NEW_RECORD",
      uniqueIndex
    )

    this.bodyTarget.insertAdjacentHTML("beforeend", rowHtml)

    const newRow = this.visibleRows.at(-1)
    const durationInput = newRow.querySelector(
      '[data-blind-structure-target="durationInput"]'
    )
    const durationLabel = newRow.querySelector(
      '[data-blind-structure-target="durationLabel"]'
    )

    durationInput.value = this.durationTarget.value
    durationLabel.textContent = `${this.durationTarget.value} min`
  }

  markForRemoval(row) {
    const destroyInput = row.querySelector(
      '[data-blind-structure-target="destroyInput"]'
    )

    destroyInput.value = "1"
    row.hidden = true
  }

  synchronize() {
    this.visibleRows.forEach((row, index) => {
      const level = index + 1

      row.querySelector(
        '[data-blind-structure-target="levelInput"]'
      ).value = level

      row.querySelector(
        '[data-blind-structure-target="levelLabel"]'
      ).textContent = level
    })

    this.countTarget.value = this.visibleRows.length

    const removalDisabled =
      this.visibleRows.length <= this.minimumLevels

    this.removeButtonTargets.forEach((button) => {
      button.disabled = removalDisabled
    })
  }

  rowHasValues(row) {
    const smallBlind = row.querySelector(
      '[data-blind-structure-target="smallBlind"]'
    ).value

    const bigBlind = row.querySelector(
      '[data-blind-structure-target="bigBlind"]'
    ).value

    const ante = row.querySelector(
      'input[name*="[ante]"]'
    ).value

    return smallBlind !== "" || bigBlind !== "" || ante !== ""
  }

  get visibleRows() {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  get durationInputs() {
    return this.durationInputTargets.filter(
      (input) => !input.closest("tr").hidden
    )
  }

  get minimumLevels() {
    return 5
  }
}
