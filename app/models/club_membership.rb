class ClubMembership < ApplicationRecord
  belongs_to :user
  belongs_to :club

  enum :role, {
    owner: "owner",
    admin: "admin",
    dealer: "dealer",
    player: "player"
  }

  validates :user_id,
            uniqueness: {
              scope: :club_id,
              message: "já pertence a este clube"
            }

end
