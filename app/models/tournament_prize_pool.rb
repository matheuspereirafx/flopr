class TournamentPrizePool < ApplicationRecord
  belongs_to :tournament
  has_many :prize_positions,
           class_name: "TournamentPrizePosition",
           dependent: :destroy,
           inverse_of: :prize_pool

  accepts_nested_attributes_for :prize_positions, allow_destroy: true

  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validate :percentages_total_one_hundred
  validate :positions_are_unique

  private

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
