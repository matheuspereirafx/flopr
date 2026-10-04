class TournamentPrizePosition < ApplicationRecord
  belongs_to :prize_pool, class_name: "TournamentPrizePool",
             foreign_key: :tournament_prize_pool_id,
             inverse_of: :prize_positions

  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :tournament_prize_pool_id }
  validates :percentage, presence: true,
                         numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validate :percentage_is_integer_input

  private

  def percentage_is_integer_input
    value = percentage_before_type_cast
    return if value.blank? || value.is_a?(Integer)
    return if value.to_s.match?(/\A\d+\z/)

    errors.add(:percentage, "deve ser um número inteiro")
  end
end
