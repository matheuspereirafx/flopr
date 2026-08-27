class TournamentRegistration < ApplicationRecord
  RECHARGE_REQUEST_COOLDOWN = 5.seconds

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

  def can_request_recharge?(at: Time.current)
    latest_recharge.blank? || latest_recharge.created_at <= at - RECHARGE_REQUEST_COOLDOWN
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
