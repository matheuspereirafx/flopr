require "test_helper"

class SubscriptionProrationCalculatorTest < ActiveSupport::TestCase
  test "calculates the remaining monthly credit and upgrade amount" do
    current_plan = Plan.new(price: 190, billing_period: :monthly)
    new_plan = Plan.new(price: 290, billing_period: :monthly)
    ends_at = Time.zone.parse("2026-11-01 00:00:00")
    current_subscription = ClubSubscription.new(
      plan: current_plan,
      billing_period: :monthly,
      expires_at: ends_at
    )
    now = Time.zone.parse("2026-10-01 00:00:00")

    result = SubscriptionProrationCalculator.new(
      current_subscription: current_subscription,
      new_plan: new_plan,
      now: now
    ).call

    assert_equal 190.to_d, result.credit_amount
    assert_equal 100.to_d, result.upgrade_amount
  end

  test "does not create credit for a free current plan" do
    current_plan = Plan.new(price: 0, billing_period: :monthly)
    new_plan = Plan.new(price: 290, billing_period: :monthly)
    current_subscription = ClubSubscription.new(
      plan: current_plan,
      billing_period: :monthly
    )

    result = SubscriptionProrationCalculator.new(
      current_subscription: current_subscription,
      new_plan: new_plan,
      now: Time.current
    ).call

    assert_equal 0.to_d, result.credit_amount
    assert_equal 290.to_d, result.upgrade_amount
  end
end
