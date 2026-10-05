class Club < ApplicationRecord
  has_many :tournaments, dependent: :destroy
  has_many :club_memberships, dependent: :destroy
  has_many :club_subscriptions, dependent: :restrict_with_exception

  has_one :active_club_subscription,
          -> { where(status: "active") },
          class_name: "ClubSubscription"

  has_many :members,
           through: :club_memberships,
           source: :user

  has_one :owner_membership,
          -> { where(role: "owner") },
          class_name: "ClubMembership"

  has_one :owner,
          through: :owner_membership,
          source: :user

  validates :name, presence: true
  validates :pix_key_type,
            inclusion: { in: %w[cpf cnpj email phone random] },
            allow_blank: true
  validates :pix_recipient_name, presence: true, if: -> { pix_key.present? }
  validates :pix_key, presence: true, if: -> { pix_key_type.present? || pix_recipient_name.present? }

  def active_plan
    active_club_subscription&.plan
  end

  def plan_allows?(feature)
    active_plan&.allows_feature?(feature) || false
  end

  def started_tournaments_in_month(reference_time = Time.current)
    tournaments.where(clock_started_at: reference_time.all_month)
  end

  def can_create_tournament?(reference_time = Time.current)
    return true unless active_plan&.free?

    tournaments.where(created_at: reference_time.all_month).count < active_plan.monthly_tournament_limit
  end

  def can_start_tournament?
    plan = active_plan
    return false unless plan

    started_tournaments_in_month.count < plan.monthly_tournament_limit
  end
end
