ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/tournament_clock_test_helpers"
require_relative "support/registration_payment_test_helpers"

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include RegistrationPaymentTestHelpers
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
    include RegistrationPaymentTestHelpers

    # Add more helper methods to be used by all tests here...
  end
end
