class TournamentPrizePosition < ApplicationRecord
  belongs_to :prize_pool, class_name: "TournamentPrizePool",
             foreign_key: :tournament_prize_pool_id,
             inverse_of: :prize_positions

  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :tournament_prize_pool_id }
  validates :percentage, presence: true,
                         numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
