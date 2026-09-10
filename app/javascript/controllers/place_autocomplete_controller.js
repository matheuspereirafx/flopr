import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "placeId", "message"]
  static values = { apiKey: String }

  connect() {
    this.loadGooglePlaces()
  }

  async loadGooglePlaces() {
    if (!this.apiKeyValue) {
      this.showMessage("A busca de endereços não está configurada.")
      return
    }

    try {
      await this.loadScript()
      const { Autocomplete } = await google.maps.importLibrary("places")
      this.autocomplete = new Autocomplete(this.inputTarget, {
        componentRestrictions: { country: "br" },
        fields: ["formatted_address", "place_id"]
      })
      this.autocomplete.addListener("place_changed", () => this.selectPlace())
    } catch (_error) {
      this.showMessage("Não foi possível carregar a busca de endereços.")
    }
  }

  selectPlace() {
    const place = this.autocomplete.getPlace()

    if (!place.place_id || !place.formatted_address) {
      this.placeIdTarget.value = ""
      this.showMessage("Selecione um endereço válido nas sugestões.")
      return
    }

    this.inputTarget.value = place.formatted_address
    this.placeIdTarget.value = place.place_id
    this.hideMessage()
  }

  clearSelection() {
    this.placeIdTarget.value = ""
  }

  loadScript() {
    if (window.google?.maps) return Promise.resolve()
    if (window.googleMapsScriptPromise) return window.googleMapsScriptPromise

    window.googleMapsScriptPromise = new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(this.apiKeyValue)}&libraries=places&v=weekly`
      script.async = true
      script.defer = true
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })

    return window.googleMapsScriptPromise
  }

  showMessage(message) {
    this.messageTarget.textContent = message
    this.messageTarget.hidden = false
  }

  hideMessage() {
    this.messageTarget.hidden = true
  }
}
