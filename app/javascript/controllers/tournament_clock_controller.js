import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "timer", "audio", "soundDialog", "soundButton", "level", "duration", "status", "statusLabel",
    "smallBlind", "bigBlind", "ante", "nextLevelLabel", "nextLevelValues",
    "nextLevelDuration"
  ]

  static values = {
    seconds: Number,
    running: Boolean,
    overtime: Boolean,
    currentLevelId: Number,
    totalLevels: Number,
    totalLevelSeconds: Number,
    hasNextLevel: Boolean,
    soundStorageKey: String,
    stateUrl: String
  }

  connect() {
    this.startedAt = Date.now()
    this.alertedLevelId = null
    this.soundEnabled = this.soundWasEnabled()
    this.render()
    this.interval = window.setInterval(() => this.render(), 1000)
    this.preventSoundDialogClose = (event) => event.preventDefault()
    this.soundDialogTarget.addEventListener("cancel", this.preventSoundDialogClose)
    if (!this.soundEnabled) this.soundDialogTarget.showModal()
  }

  disconnect() {
    window.clearInterval(this.interval)
    this.soundDialogTarget.removeEventListener("cancel", this.preventSoundDialogClose)
  }

  render() {
    const seconds = this.displaySeconds()

    this.timerTarget.textContent = `${this.overtimeValue ? "+" : ""}${this.format(seconds)}`
    this.timerTarget.classList.toggle(
      "tournament-clock-timer__value--ending",
      !this.overtimeValue && seconds > 0 && seconds <= 12
    )
    this.playEndingAlert(seconds)
    this.requestTransitionWhenFinished(seconds)
    this.renderTotalTournamentDuration(seconds)
  }

  displaySeconds() {
    const elapsedSeconds = this.runningValue
      ? Math.floor((Date.now() - this.startedAt) / 1000)
      : 0
    return this.overtimeValue
      ? this.secondsValue + elapsedSeconds
      : Math.max(this.secondsValue - elapsedSeconds, 0)
  }

  enableSound() {
    this.audioTarget.play()
      .then(() => {
        this.audioTarget.pause()
        this.audioTarget.currentTime = 0
        this.soundEnabled = true
        this.persistSoundPreference()
        this.soundDialogTarget.close()
        this.playEndingAlert(this.displaySeconds())
      })
      .catch(() => {})
  }

  stateTargetConnected(target) {
    this.applyState(JSON.parse(target.dataset.tournamentClockStatePayload))
  }

  applyState(state) {
    this.secondsValue = state.status === "overtime"
      ? state.overtime_elapsed_seconds
      : state.remaining_seconds
    this.runningValue = state.status === "running" || state.status === "overtime"
    this.overtimeValue = state.status === "overtime"
    this.startedAt = Date.now()

    if (state.current_level.id !== this.currentLevelIdValue) {
      this.currentLevelIdValue = state.current_level.id
      this.alertedLevelId = null
      this.transitionRequestedLevelId = null
      this.updateLevelDetails(state.current_level, state.next_level)
    }

    this.hasNextLevelValue = Boolean(state.next_level)

    this.updateStatus(state.status)
    this.render()
  }

  updateLevelDetails(currentLevel, nextLevel) {
    this.levelTarget.textContent = `LEVEL ${currentLevel.level} A ${this.totalLevelsValue}`
    this.durationTarget.textContent = `◷ ${currentLevel.duration_minutes} min de duração`
    this.smallBlindTarget.textContent = this.formatNumber(currentLevel.small_blind)
    this.bigBlindTarget.textContent = this.formatNumber(currentLevel.big_blind)
    this.anteTarget.textContent = this.formatNumber(currentLevel.ante)

    if (nextLevel) {
      this.nextLevelLabelTarget.textContent = `Próximo nível (${nextLevel.level})`
      this.nextLevelValuesTarget.textContent = `${this.formatNumber(nextLevel.small_blind)} / ${this.formatNumber(nextLevel.big_blind)} / ${this.formatNumber(nextLevel.ante)}`
      this.nextLevelDurationTarget.textContent = `${nextLevel.duration_minutes} min`
    } else {
      this.nextLevelLabelTarget.textContent = "Estrutura de blinds"
      this.nextLevelValuesTarget.textContent = "Último nível configurado"
      this.nextLevelDurationTarget.textContent = ""
    }
  }

  renderTotalTournamentDuration(overtimeSeconds) {
    if (this.hasNextLevelValue || !this.overtimeValue) return

    const totalSeconds = this.totalLevelSecondsValue + overtimeSeconds
    this.nextLevelDurationTarget.textContent = `Total: ${this.formatDuration(totalSeconds)}`
  }

  updateStatus(status) {
    this.statusTarget.className = `tournament-clock-status tournament-clock-status--${status}`
    this.statusLabelTarget.textContent = {
      not_started: "Não iniciado",
      running: "Em execução",
      paused: "Pausado",
      overtime: "Tempo extra",
      finished: "Finalizado"
    }[status]
  }

  playEndingAlert(seconds) {
    if (this.overtimeValue || seconds <= 0 || seconds > 12) return
    if (this.alertedLevelId === this.currentLevelIdValue) return
    if (!this.soundEnabled) return

    this.audioTarget.currentTime = Math.max(0, 12 - seconds)
    this.audioTarget.play().catch(() => {})
    this.alertedLevelId = this.currentLevelIdValue
  }

  requestTransitionWhenFinished(seconds) {
    if (!this.runningValue || this.overtimeValue || seconds > 0) return
    if (this.transitionRequestedLevelId === this.currentLevelIdValue) return

    this.transitionRequestedLevelId = this.currentLevelIdValue

    fetch(this.stateUrlValue, {
      headers: { Accept: "application/json" },
      credentials: "same-origin"
    })
      .then((response) => response.ok ? response.json() : Promise.reject())
      .then((state) => this.applyState(state))
      .catch(() => {
        this.transitionRequestedLevelId = null
      })
  }

  soundWasEnabled() {
    try {
      return localStorage.getItem(this.soundStorageKeyValue) === "enabled"
    } catch (_) {
      return false
    }
  }

  persistSoundPreference() {
    try {
      localStorage.setItem(this.soundStorageKeyValue, "enabled")
    } catch (_) {
      // O áudio permanece ativo nesta página quando o armazenamento não está disponível.
    }
  }

  formatNumber(number) {
    return new Intl.NumberFormat("pt-BR").format(number)
  }

  formatDuration(seconds) {
    const hours = Math.floor(seconds / 3600).toString().padStart(2, "0")
    const minutes = Math.floor((seconds % 3600) / 60).toString().padStart(2, "0")
    const remainder = (seconds % 60).toString().padStart(2, "0")

    return `${hours}:${minutes}:${remainder}`
  }

  format(seconds) {
    const minutes = Math.floor(seconds / 60).toString().padStart(2, "0")
    const remainder = (seconds % 60).toString().padStart(2, "0")

    return `${minutes} : ${remainder}`
  }
}
