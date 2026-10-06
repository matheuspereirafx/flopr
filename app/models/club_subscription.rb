class ClubSubscription < ApplicationRecord
  belongs_to :club
  belongs_to :plan
  belongs_to :owner, class_name: "User"

  enum :status, {
    active: "active",
    canceled: "canceled",
    expired: "expired"
  }

  enum :billing_period, {
    monthly: "monthly",
    yearly: "yearly"
  }

  validates :billing_period, presence: true
  validate :only_one_active_subscription_per_club, if: :active?

  def valid_at?(time = Time.current)
    active? && (expires_at.blank? || expires_at > time)
  end

  private

  def only_one_active_subscription_per_club
    return unless club

    relation = club.club_subscriptions.active
    relation = relation.where.not(id: id) if persisted?
    return unless relation.exists?

    errors.add(:club, "já possui uma assinatura ativa")
  end
end
