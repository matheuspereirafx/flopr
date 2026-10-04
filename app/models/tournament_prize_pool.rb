class TournamentPrizePool < ApplicationRecord
  belongs_to :tournament
  has_many :prize_positions,
           class_name: "TournamentPrizePosition",
           dependent: :destroy,
           inverse_of: :prize_pool

  accepts_nested_attributes_for :prize_positions, allow_destroy: true

  validates :total_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :rake_percentage, presence: true,
                              numericality: {
                                only_integer: true,
                                greater_than_or_equal_to: 0,
                                less_than_or_equal_to: 100
                              }
  validate :rake_percentage_is_integer_input
  validate :percentages_total_one_hundred
  validate :positions_are_unique

  def gross_amount
    tournament.registration_payments.eligible_for_prize_pool.sum(:amount)
  end

  def rake_amount
    (gross_amount * rake_percentage.to_d / 100).round(2)
  end

  def net_amount
    (gross_amount - rake_amount).round(2)
  end

  private

  def rake_percentage_is_integer_input
    value = rake_percentage_before_type_cast
    return if value.blank? || value.is_a?(Integer)
    return if value.to_s.match?(/\A-?\d+\z/)

    errors.add(:rake_percentage, "deve ser um número inteiro")
  end

  def percentages_total_one_hundred
    total = prize_positions.reject(&:marked_for_destruction?)
                           .sum { |position| position.percentage.to_d }
    return if total == 100.to_d

    errors.add(:base, "os percentuais devem totalizar 100%")
  end

  def positions_are_unique
    positions = prize_positions.reject(&:marked_for_destruction?).map(&:position)
    return if positions.compact.uniq.size == positions.compact.size

    errors.add(:base, "as posições não podem se repetir")
  end
end
