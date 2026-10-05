ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/tournament_clock_test_helpers"
require_relative "support/registration_payment_test_helpers"

module PlanAccessTestHelpers
  def enable_paid_plan(club, owner, price: 290)
    plan = Plan.create!(
      name: "Test paid plan #{SecureRandom.uuid}",
      description: "Plano de teste",
      price: price,
      billing_period: :monthly,
      active: true
    )

    ClubSubscription.create!(
      club: club,
      plan: plan,
      owner: owner,
      status: :active,
      billing_period: plan.billing_period
    )
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include RegistrationPaymentTestHelpers
  include PlanAccessTestHelpers
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
    include RegistrationPaymentTestHelpers
    include PlanAccessTestHelpers

    # Add more helper methods to be used by all tests here...
  end
end
