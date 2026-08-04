import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["option","button"]

  select(event){

    this.optionTargets.forEach((option)=>{
      option.classList.remove("selected")
    })

    event.currentTarget.classList.add("selected")

    const role = event.currentTarget.dataset.value

    this.buttonTarget.href = `/users/sign_in?role=${role}`

  }

}
