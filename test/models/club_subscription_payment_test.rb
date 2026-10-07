require "test_helper"

class ClubSubscriptionPaymentTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "subscription-payment-owner-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Owner",
      username: "subscription_payment_owner_#{SecureRandom.hex(4)}"
    )
    @club = Club.create!(name: "Subscription Payment Club #{SecureRandom.hex(4)}")
    @plan = Plan.create!(
      name: "Payment Plan #{SecureRandom.hex(4)}",
      description: "Plano de teste",
      price: 49,
      billing_period: :monthly,
      active: true
    )
    @subscription = ClubSubscription.create!(
      club: @club,
      plan: @plan,
      owner: @owner,
      status: :pending,
      billing_period: @plan.billing_period,
      asaas_subscription_id: "sub_#{SecureRandom.hex(8)}"
    )
  end

  test "belongs to a club subscription" do
    payment = ClubSubscriptionPayment.new(
      club_subscription: @subscription,
      provider: "asaas",
      provider_payment_id: "pay_#{SecureRandom.hex(8)}",
      status: :pending,
      amount: @plan.price
    )

    assert_equal @subscription, payment.club_subscription
  end

  test "supports pending approved and rejected statuses" do
    %i[pending approved rejected].each do |status|
      payment = ClubSubscriptionPayment.new(
        club_subscription: @subscription,
        provider: "asaas",
        provider_payment_id: "pay_#{SecureRandom.hex(8)}",
        status: status,
        amount: @plan.price
      )

      assert_predicate payment, :valid?
      assert payment.public_send("#{status}?")
    end
  end

  test "rejects a negative amount" do
    payment = ClubSubscriptionPayment.new(
      club_subscription: @subscription,
      provider: "asaas",
      provider_payment_id: "pay_#{SecureRandom.hex(8)}",
      status: :pending,
      amount: -1
    )

    assert_not_predicate payment, :valid?
  end

  test "does not allow duplicate provider payment identifiers" do
    provider_payment_id = "pay_#{SecureRandom.hex(8)}"
    attributes = {
      club_subscription: @subscription,
      provider: "asaas",
      provider_payment_id: provider_payment_id,
      status: :approved,
      amount: @plan.price
    }

    ClubSubscriptionPayment.create!(attributes)
    duplicate = ClubSubscriptionPayment.new(attributes)

    assert_not_predicate duplicate, :valid?
  end
end
