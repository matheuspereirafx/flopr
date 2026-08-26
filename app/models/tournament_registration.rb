class TournamentRegistration < ApplicationRecord
  belongs_to :tournament
  belongs_to :user

  has_many :registration_payments,
           dependent: :destroy

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
