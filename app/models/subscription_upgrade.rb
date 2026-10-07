class SubscriptionUpgrade < ApplicationRecord
  belongs_to :club
  belongs_to :current_subscription, class_name: "ClubSubscription"
  belongs_to :new_subscription, class_name: "ClubSubscription"
  belongs_to :current_plan, class_name: "Plan"
  belongs_to :new_plan, class_name: "Plan"
  belongs_to :requested_by, class_name: "User"

  enum :status, {
    pending_payment: "pending_payment",
    payment_approved: "payment_approved",
    provider_sync_pending: "provider_sync_pending",
    applied: "applied",
    rejected: "rejected",
    canceled: "canceled",
    failed: "failed"
  }

  validates :original_amount, :credit_amount, :upgrade_amount,
            numericality: { greater_than_or_equal_to: 0 }
  validates :period_started_at, :period_ends_at, :external_reference, presence: true
  validates :external_reference, uniqueness: true
  validate :plans_must_be_upgrade
  validate :subscriptions_must_belong_to_club

  private

  def plans_must_be_upgrade
    return if current_plan.blank? || new_plan.blank?
    return if new_plan.price.to_d > current_plan.price.to_d

    errors.add(:new_plan, "deve ser superior ao plano atual")
  end

  def subscriptions_must_belong_to_club
    return if club.blank? || current_subscription.blank? || new_subscription.blank?
    return if current_subscription.club_id == club_id && new_subscription.club_id == club_id

    errors.add(:club, "não corresponde às assinaturas")
  end
end
