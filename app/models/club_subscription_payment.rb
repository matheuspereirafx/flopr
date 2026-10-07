class ClubSubscriptionPayment < ApplicationRecord
  belongs_to :club_subscription
  has_many :subscription_webhook_events, dependent: :nullify

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }

  validates :provider, :status, :amount, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :provider_payment_id,
            uniqueness: { scope: :provider },
            allow_blank: true
end
