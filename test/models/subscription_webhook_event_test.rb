require "test_helper"

class SubscriptionWebhookEventTest < ActiveSupport::TestCase
  test "requires a provider and an external event identifier" do
    event = SubscriptionWebhookEvent.new

    assert_not_predicate event, :valid?
    assert_predicate event.errors[:provider], :present?
    assert_predicate event.errors[:provider_event_id], :present?
  end

  test "does not allow duplicate provider event identifiers" do
    provider_event_id = "evt_#{SecureRandom.hex(8)}"
    SubscriptionWebhookEvent.create!(
      provider: "asaas",
      provider_event_id: provider_event_id,
      event_type: "PAYMENT_CONFIRMED"
    )

    duplicate = SubscriptionWebhookEvent.new(
      provider: "asaas",
      provider_event_id: provider_event_id,
      event_type: "PAYMENT_CONFIRMED"
    )

    assert_not_predicate duplicate, :valid?
  end

  test "can retain an event before its subscription is resolved" do
    event = SubscriptionWebhookEvent.new(
      provider: "asaas",
      provider_event_id: "evt_#{SecureRandom.hex(8)}",
      event_type: "PAYMENT_CONFIRMED"
    )

    assert_predicate event, :valid?
  end
end
