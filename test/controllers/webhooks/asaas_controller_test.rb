require "test_helper"

class AsaasWebhookProcessorDouble
  attr_reader :calls

  def initialize
    @calls = []
  end

  def call(event_id)
    @calls << event_id
    true
  end
end

module Asaas
  class WebhookProcessor
    class << self
      attr_accessor :test_double
    end

    def self.new(*)
      test_double
    end
  end
end

class AsaasWebhookControllerTest < ActionDispatch::IntegrationTest
  teardown do
    Asaas::WebhookProcessor.test_double = nil
  end

  setup do
    @owner = create_user("webhook-owner")
    @club = Club.create!(name: "Webhook Club")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    @plan = Plan.create!(
      name: "Webhook Plan",
      description: "Plano de webhook",
      price: 49,
      billing_period: :monthly,
      active: true
    )
    @subscription = ClubSubscription.create!(
      club: @club,
      plan: @plan,
      owner: @owner,
      status: :active,
      billing_period: @plan.billing_period
    )
  end

  test "processes an approved payment without an authenticated user" do
    processor = AsaasWebhookProcessorDouble.new

    Asaas::WebhookProcessor.test_double = processor
    post "/webhooks/asaas",
         params: {
           id: "evt_approved",
           event: "PAYMENT_CONFIRMED",
           payment: { subscription: "sub_webhook", id: "pay_approved" }
         }.to_json,
         headers: webhook_headers
    Asaas::WebhookProcessor.test_double = nil

    assert_response :success
    assert_equal ["evt_approved"], processor.calls
  end

  test "rejects an unauthenticated webhook" do
    assert_no_difference("SubscriptionWebhookEvent.count") do
      post "/webhooks/asaas",
           params: { id: "evt_invalid", event: "PAYMENT_CONFIRMED" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "X-Asaas-Webhook-Token" => "invalid" }
    end

    assert_response :unauthorized
  end

  test "does not process the same external event twice" do
    SubscriptionWebhookEvent.create!(
      provider: "asaas",
      provider_event_id: "evt_duplicate",
      event_type: "PAYMENT_CONFIRMED"
    )

    processor = AsaasWebhookProcessorDouble.new
    Asaas::WebhookProcessor.test_double = processor
    post "/webhooks/asaas",
         params: {
           id: "evt_duplicate",
           event: "PAYMENT_CONFIRMED",
           payment: { subscription: "sub_webhook", id: "pay_duplicate" }
         }.to_json,
         headers: webhook_headers
    Asaas::WebhookProcessor.test_double = nil

    assert_response :success
    assert_empty processor.calls
  end

  test "cancels provider billing while preserving local access until expiration" do
    @subscription.update!(status: :active, expires_at: 1.month.from_now)
    processor = AsaasWebhookProcessorDouble.new

    Asaas::WebhookProcessor.test_double = processor
    post "/webhooks/asaas",
         params: {
           id: "evt_canceled",
           event: "SUBSCRIPTION_DELETED",
           subscription: { id: "sub_webhook" }
         }.to_json,
         headers: webhook_headers
    Asaas::WebhookProcessor.test_double = nil

    assert_response :success
    assert @subscription.reload.valid_at?
    assert_equal ["evt_canceled"], processor.calls
  end

  private

  def create_user(username)
    username = username.tr("-", "_")

    User.create!(
      email: "#{username}@example.com",
      password: "password123",
      name: username.capitalize,
      username: username
    )
  end

  def webhook_headers
    {
      "CONTENT_TYPE" => "application/json",
      "X-Asaas-Webhook-Token" => "test-token"
    }
  end
end
