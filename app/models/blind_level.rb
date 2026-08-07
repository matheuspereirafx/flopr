class BlindLevel < ApplicationRecord
  belongs_to :tournament

  validates :level, :duration_minutes, presence: true,
    numericality: { only_integer: true, greater_than: 0 }

  validates :small_blind, :big_blind, :ante, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :big_blind_cannot_be_less_than_small_blind

  validates :duration_minutes,
          presence: true,
          numericality: {
            only_integer: true,
            greater_than_or_equal_to: 5
          }

  private

  def big_blind_cannot_be_less_than_small_blind
    return if small_blind.blank? || big_blind.blank?
    return if big_blind >= small_blind

    errors.add(:big_blind, "deve ser maior ou igual ao small blind")
  end
end
