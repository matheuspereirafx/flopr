// Import and register all your controllers from the importmap via controllers/**/*_controller

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import PasswordToggleController from "./password_toggle_controller"
import TournamentClockController from "./tournament_clock_controller"
import BuyInPaymentController from "./buy_in_payment_controller"
import RechargePaymentController from "./recharge_payment_controller"
import PrizePoolFormController from "./prize_pool_form_controller"
import PrizePoolScrollController from "./prize_pool_scroll_controller"
import PlaceAutocompleteController from "./place_autocomplete_controller"

eagerLoadControllersFrom("controllers", application)

application.register(
  "password-toggle",
  PasswordToggleController
)

application.register(
  "tournament-clock",
  TournamentClockController
)

application.register(
  "buy-in-payment",
  BuyInPaymentController
)

application.register(
  "recharge-payment",
  RechargePaymentController
)

application.register("prize-pool-form", PrizePoolFormController)
application.register("prize-pool-scroll", PrizePoolScrollController)
application.register("place-autocomplete", PlaceAutocompleteController)
