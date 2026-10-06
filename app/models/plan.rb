class Plan < ApplicationRecord
  PAID_FEATURES = %i[
    invitations
    guest_list
    buy_ins
    transactions
    recharges
    prize_pool
  ].freeze

  has_many :club_subscriptions, dependent: :restrict_with_exception

  enum :billing_period, {
    monthly: "monthly",
    yearly: "yearly"
  }

  scope :active, -> { where(active: true) }

  validates :name, :description, :price, :billing_period, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  def free?
    price.to_d.zero?
  end

  def subscription_expires_at(started_at = Time.current)
    return if free?

    started_at + (yearly? ? 1.year : 1.month)
  end

  def allows_feature?(feature)
    return true if %i[create_tournament configure_blinds timer].include?(feature.to_sym)

    PAID_FEATURES.include?(feature.to_sym) && !free?
  end

  def monthly_tournament_limit
    return 1 if free? || name == "Free"
    return 4 if name.to_s.start_with?("Iniciante") || price.to_d == 190.to_d
    return 9 if name.to_s.start_with?("Profissional") || price.to_d == 290.to_d

    0
  end
end
