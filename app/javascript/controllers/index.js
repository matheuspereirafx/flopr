// Import and register all your controllers from the importmap via controllers/**/*_controller

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import PasswordToggleController from "./password_toggle_controller"
import TournamentClockController from "./tournament_clock_controller"
import BuyInPaymentController from "./buy_in_payment_controller"

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
