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
      const { PlaceAutocompleteElement } = await google.maps.importLibrary("places")
      const autocomplete = new PlaceAutocompleteElement({
        includedRegionCodes: ["br"]
      })
      autocomplete.id = this.inputTarget.id
      autocomplete.value = this.inputTarget.value
      autocomplete.addEventListener("gmp-select", (event) => this.selectPlace(event))

      this.inputTarget.replaceWith(autocomplete)
      this.inputTarget = autocomplete
    } catch (_error) {
      this.showMessage("Não foi possível carregar a busca de endereços.")
    }
  }

  async selectPlace(event) {
    const place = event.placePrediction.toPlace()
    await place.fetchFields({ fields: ["formattedAddress", "id"] })

    this.inputTarget.value = place.formattedAddress || ""
    this.placeIdTarget.value = place.id || ""
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
      script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(this.apiKeyValue)}&v=weekly`
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
