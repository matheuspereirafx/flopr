class SubscriptionWebhookEvent < ApplicationRecord
  belongs_to :club_subscription, optional: true
  belongs_to :club_subscription_payment, optional: true

  validates :provider, :provider_event_id, :event_type, presence: true
  validates :provider_event_id, uniqueness: { scope: :provider }
end
