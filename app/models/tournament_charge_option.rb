class TournamentChargeOption < ApplicationRecord
  KINDS = %w[buy_in rebuy double_rebuy addon fee].freeze

  belongs_to :tournament
  belongs_to :available_from_level,
             class_name: "BlindLevel",
             optional: true
  belongs_to :available_until_level,
             class_name: "BlindLevel",
             optional: true

  enum :kind, KINDS.index_with { |kind| kind }

  validates :kind, uniqueness: { scope: :tournament_id }
  validates :amount, :chip_amount, presence: true, if: :active?
  validates :amount,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :chip_amount,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validate :buy_in_has_no_availability_period
  validate :availability_levels_belong_to_tournament
  validate :availability_period_is_ordered

  private

  def buy_in_has_no_availability_period
    return unless buy_in?
    return if available_from_level.blank? && available_until_level.blank?

    errors.add(:base, "buy-in não possui período de disponibilidade")
  end

  def availability_levels_belong_to_tournament
    [available_from_level, available_until_level].compact.each do |blind_level|
      next if blind_level.tournament_id == tournament_id

      errors.add(:base, "o nível de blind deve pertencer ao torneio")
    end
  end

  def availability_period_is_ordered
    return if available_from_level.blank? || available_until_level.blank?
    return if available_from_level.level <= available_until_level.level

    errors.add(:available_until_level,
               "deve ser posterior ao início da disponibilidade")
  end
end
