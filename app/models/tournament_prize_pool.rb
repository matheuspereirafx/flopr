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
  validate :has_at_least_one_position
  validate :percentages_total_one_hundred
  validate :positions_are_unique
  validate :positions_are_sequential

  def gross_amount
    tournament.registration_payments.eligible_for_prize_pool.sum(:amount)
  end

  def rake_amount
    (gross_amount * rake_percentage.to_d / 100).round(2)
  end

  def net_amount
    (gross_amount - rake_amount).round(2)
  end

  def prize_distribution
    positions = active_prize_positions.sort_by(&:position)
    remaining_amount = net_amount

    positions.each_with_index.map do |prize_position, index|
      amount = if index == positions.length - 1
                 remaining_amount.round(2)
               else
                 (net_amount * prize_position.percentage.to_d / 100).round(2)
               end

      remaining_amount -= amount

      {
        position: prize_position,
        amount: amount.round(2)
      }
    end
  end

  def prize_amount_for(prize_position)
    prize_distribution.find { |entry| entry[:position] == prize_position }&.fetch(:amount, 0.to_d) || 0.to_d
  end

  private

  def rake_percentage_is_integer_input
    value = rake_percentage_before_type_cast
    return if value.blank? || value.is_a?(Integer)
    return if value.to_s.match?(/\A-?\d+\z/)

    errors.add(:rake_percentage, "deve ser um número inteiro")
  end

  def percentages_total_one_hundred
    total = active_prize_positions
                           .sum { |position| position.percentage.to_d }
    return if total == 100.to_d

    errors.add(:base, "os percentuais devem totalizar 100%")
  end

  def has_at_least_one_position
    return if active_prize_positions.any?

    errors.add(:base, "deve existir pelo menos uma posição")
  end

  def positions_are_unique
    positions = active_prize_positions.map(&:position)
    return if positions.compact.uniq.size == positions.compact.size

    errors.add(:base, "as posições não podem se repetir")
  end

  def positions_are_sequential
    positions = active_prize_positions.map(&:position).sort
    return if positions.any?(&:blank?)
    return if positions == (1..positions.size).to_a

    errors.add(:base, "as posições devem ser sequenciais")
  end

  def active_prize_positions
    prize_positions.reject(&:marked_for_destruction?)
  end
end
