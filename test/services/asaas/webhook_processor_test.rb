require "test_helper"

class AsaasWebhookProcessorTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "processor-owner@example.com",
      password: "password123",
      name: "Processor Owner",
      username: "processor_owner"
    )
    @club = Club.create!(name: "Processor Club")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    @free_plan = Plan.create!(
      name: "Free",
      description: "Plano gratuito",
      price: 0,
      billing_period: :monthly,
      active: true
    )
    @paid_plan = Plan.create!(
      name: "Pro",
      description: "Plano pago",
      price: 190,
      billing_period: :monthly,
      active: true
    )
    @current_subscription = ClubSubscription.create!(
      club: @club,
      plan: @free_plan,
      owner: @owner,
      status: :active,
      billing_period: :monthly
    )
    @pending_subscription = ClubSubscription.create!(
      club: @club,
      plan: @paid_plan,
      owner: @owner,
      status: :pending,
      billing_period: :monthly,
      asaas_subscription_id: "sub_processor"
    )
  end

  test "activates the paid plan after receiving payment and ends the previous active plan" do
    event = Asaas::WebhookProcessor.new(payload: payment_received_payload).call("evt_processor")

    assert_instance_of SubscriptionWebhookEvent, event
    assert_predicate @pending_subscription.reload, :active?
    assert_predicate @current_subscription.reload, :canceled?
    assert_equal 1, @pending_subscription.club_subscription_payments.count
    assert_predicate @pending_subscription.club_subscription_payments.first, :approved?
  end

  test "reprocesses an approved payment left pending by a previous failed webhook" do
    event = SubscriptionWebhookEvent.create!(
      provider: "asaas",
      provider_event_id: "evt_processor_retry",
      event_type: "PAYMENT_RECEIVED",
      payload: payment_received_payload
    )
    payment = @pending_subscription.club_subscription_payments.create!(
      provider: "asaas",
      provider_payment_id: "pay_processor_retry",
      provider_status: "RECEIVED",
      status: :approved,
      amount: @paid_plan.price,
      paid_at: Time.current
    )
    event.update!(club_subscription: @pending_subscription, club_subscription_payment: payment)

    Asaas::WebhookProcessor.new(payload: payment_received_payload("pay_processor_retry")).call("evt_processor_retry")

    assert_predicate @pending_subscription.reload, :active?
    assert_predicate @current_subscription.reload, :canceled?
  end

  private

  def payment_received_payload(payment_id = "pay_processor")
    {
      "id" => "evt_processor",
      "event" => "PAYMENT_RECEIVED",
      "payment" => {
        "id" => payment_id,
        "subscription" => "sub_processor",
        "status" => "RECEIVED",
        "value" => @paid_plan.price.to_f,
        "description" => @paid_plan.name
      }
    }
  end
end
