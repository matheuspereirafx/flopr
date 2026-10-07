class SubscriptionChange < ApplicationRecord
  belongs_to :club
  belongs_to :club_subscription
  belongs_to :current_plan, class_name: "Plan"
  belongs_to :new_plan, class_name: "Plan"
  belongs_to :requested_by, class_name: "User"

  enum :change_type, {
    downgrade: "downgrade"
  }

  enum :status, {
    pending: "pending",
    provider_sync_pending: "provider_sync_pending",
    applied: "applied",
    canceled: "canceled"
  }

  validates :effective_at, presence: true
  validate :subscription_belongs_to_club
  validate :current_plan_matches_subscription
  validate :subscription_has_expiration
  validate :new_plan_is_active_and_lower, if: :pending?
  validate :only_one_pending_change, if: :pending?

  scope :due, -> { where(status: %w[pending provider_sync_pending]).where(effective_at: ..Time.current) }

  private

  def subscription_belongs_to_club
    return if club.blank? || club_subscription.blank?
    return if club_subscription.club_id == club_id

    errors.add(:club_subscription, "não pertence ao clube")
  end

  def current_plan_matches_subscription
    return if current_plan.blank? || club_subscription.blank?
    return if club_subscription.plan_id == current_plan_id

    errors.add(:current_plan, "não corresponde à assinatura atual")
  end

  def subscription_has_expiration
    return if club_subscription.blank? || club_subscription.expires_at.present?

    errors.add(:club_subscription, "não possui data de expiração")
  end

  def new_plan_is_active_and_lower
    return errors.add(:new_plan, "deve existir") if new_plan.blank?
    return errors.add(:new_plan, "não está ativo") unless new_plan.active?
    return if current_plan.present? && current_plan.downgrade_to?(new_plan)

    errors.add(:new_plan, "deve ser inferior ao plano atual")
  end

  def only_one_pending_change
    return if club.blank?

    relation = club.subscription_changes.where(status: %w[pending provider_sync_pending])
    relation = relation.where.not(id: id) if persisted?
    return unless relation.exists?

    errors.add(:club, "já possui uma alteração pendente")
  end
end
