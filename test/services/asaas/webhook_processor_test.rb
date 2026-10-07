require "test_helper"

class AsaasSubscriptionServiceProcessorDouble
  attr_reader :canceled_ids, :created_subscriptions

  def initialize
    @canceled_ids = []
    @created_subscriptions = []
  end

  def cancel_subscription(subscription_id)
    @canceled_ids << subscription_id
  end

  def create_subscription(plan, club, next_due_date:, external_reference:)
    @created_subscriptions << [plan, club, next_due_date, external_reference]
    { customer_id: "cus_processor", subscription_id: "sub_new_processor" }
  end
end

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
    event = processor_for(payment_received_payload).call("evt_processor")

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

    processor_for(payment_received_payload("pay_processor_retry")).call("evt_processor_retry")

    assert_predicate @pending_subscription.reload, :active?
    assert_predicate @current_subscription.reload, :canceled?
  end

  test "applies an upgrade after receiving its proportional payment" do
    current_plan = Plan.create!(name: "Current", description: "Atual", price: 190, billing_period: :monthly, active: true)
    new_plan = Plan.create!(name: "New", description: "Novo", price: 290, billing_period: :monthly, active: true)
    current_subscription = @current_subscription
    current_subscription.update!(
      plan: current_plan,
      billing_period: :monthly,
      expires_at: 1.month.from_now,
      asaas_subscription_id: "sub_old_processor"
    )
    new_subscription = ClubSubscription.create!(
      club: @club,
      plan: new_plan,
      owner: @owner,
      status: :pending,
      billing_period: :monthly,
      expires_at: current_subscription.expires_at
    )
    upgrade = SubscriptionUpgrade.create!(
      club: @club,
      current_subscription: current_subscription,
      new_subscription: new_subscription,
      current_plan: current_plan,
      new_plan: new_plan,
      requested_by: @owner,
      status: :pending_payment,
      original_amount: 190,
      credit_amount: 190,
      upgrade_amount: 100,
      period_started_at: 1.month.ago,
      period_ends_at: current_subscription.expires_at,
      external_reference: "club_upgrade:processor"
    )
    processor_service = AsaasSubscriptionServiceProcessorDouble.new
    service_class = Asaas::SubscriptionService
    singleton_class = class << service_class; self; end
    original_new = singleton_class.instance_method(:new)
    singleton_class.define_method(:new) { |**| processor_service }

    begin
      processor_for({
        "event" => "PAYMENT_RECEIVED",
        "payment" => {
          "id" => "pay_upgrade_processor",
          "status" => "RECEIVED",
          "value" => 100.0,
          "externalReference" => upgrade.external_reference
        }
      }).call("evt_upgrade_processor")
    ensure
      singleton_class.define_method(:new, original_new)
    end

    assert_predicate new_subscription.reload, :active?
    assert_predicate current_subscription.reload, :canceled?
    assert_predicate upgrade.reload, :applied?
    assert_equal "sub_new_processor", new_subscription.asaas_subscription_id
    assert_equal ["sub_old_processor"], processor_service.canceled_ids
  end

  private

  def processor_for(payload)
    processor = Asaas::WebhookProcessor.allocate
    processor.send(:initialize, payload: payload)
    processor
  end

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
