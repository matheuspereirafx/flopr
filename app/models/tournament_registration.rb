class TournamentRegistration < ApplicationRecord
  belongs_to :tournament
  belongs_to :user

  has_many :registration_payments,
           dependent: :destroy

  def latest_recharge
    registration_payments
      .joins(:tournament_charge_option)
      .where.not(tournament_charge_options: { kind: :buy_in })
      .order(created_at: :desc)
      .first
  end

  def can_request_recharge?
    latest_recharge.nil? || latest_recharge.paid?
  end

  enum :status, {
    pending: "pending",
    confirmed: "confirmed"
  }

  validates :user_id,
            uniqueness: {
              scope: :tournament_id,
              message: "já possui uma inscrição neste torneio"
            }
  validates :status, presence: true
end
