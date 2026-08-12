class BlindLevel < ApplicationRecord
  belongs_to :tournament

  before_validation :set_default_ante

  validates :level,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :duration_minutes,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :small_blind,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :big_blind,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :ante,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validate :big_blind_cannot_be_less_than_small_blind

  private

  def set_default_ante
    self.ante = 0 if ante.blank?
  end

  def big_blind_cannot_be_less_than_small_blind
    return if small_blind.blank? || big_blind.blank?
    return if big_blind >= small_blind

    errors.add(:big_blind, "deve ser maior ou igual ao small blind")
  end
end
