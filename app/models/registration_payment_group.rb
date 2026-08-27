class RegistrationPaymentGroup < ApplicationRecord
  belongs_to :tournament_registration

  has_many :registration_payments,
           dependent: :destroy

  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  validates :total_amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :total_chip_amount,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true

  validate :payments_belong_to_registration

  def confirm!
    with_lock do
      unless pending? && registration_payments.exists? && registration_payments.all?(&:pending?)
        raise ActiveRecord::RecordInvalid.new(self)
      end

      ApplicationRecord.transaction do
        registration_payments.pending.find_each do |payment|
          payment.update!(status: :paid, paid_at: Time.current)
        end

        update!(status: :paid)
      end
    end
  end

  private

  def payments_belong_to_registration
    registration_payments.each do |payment|
      next if payment.tournament_registration_id == tournament_registration_id

      errors.add(:registration_payments, "devem pertencer à mesma inscrição")
    end
  end
end
