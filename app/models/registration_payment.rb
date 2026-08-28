class RegistrationPayment < ApplicationRecord
  belongs_to :tournament_registration
  belongs_to :registration_payment_group, optional: true
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

  enum :payment_method, {
    pix: "pix",
    card: "card",
    manual: "manual"
  }, validate: true

  validates :amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :chip_amount,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :provider, presence: true
  validates :provider_payment_id, uniqueness: { scope: :provider }, allow_blank: true
  validate :payment_resources_belong_to_same_tournament
  validate :payment_group_belongs_to_same_registration

  private

  def payment_resources_belong_to_same_tournament
    return if tournament_registration.blank? || tournament_charge_option.blank?
    return if tournament_registration.tournament_id == tournament_charge_option.tournament_id

    errors.add(:base, "a inscrição e a opção de cobrança devem pertencer ao mesmo torneio")
  end

  def payment_group_belongs_to_same_registration
    return if registration_payment_group.blank? || tournament_registration.blank?
    return if registration_payment_group.tournament_registration_id == tournament_registration_id

    errors.add(:base, "o grupo e o pagamento devem pertencer à mesma inscrição")
  end
end
