class RegistrationPayment < ApplicationRecord
  belongs_to :tournament_registration
  belongs_to :tournament_charge_option
  belongs_to :recorded_by,
             class_name: "User"

  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  validates :amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :provider, :payment_method, presence: true
  validates :provider_payment_id, uniqueness: { scope: :provider }, allow_blank: true
  validate :payment_resources_belong_to_same_tournament

  private

  def payment_resources_belong_to_same_tournament
    return if tournament_registration.blank? || tournament_charge_option.blank?
    return if tournament_registration.tournament_id == tournament_charge_option.tournament_id

    errors.add(:base, "a inscrição e a opção de cobrança devem pertencer ao mesmo torneio")
  end
end
