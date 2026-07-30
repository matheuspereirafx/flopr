class ClubMembership < ApplicationRecord
  belongs_to :user
  belongs_to :club

  enum :role, {
    owner: "owner",
    admin: "admin",
    member: "member"
  }

  validates :user_id,
            uniqueness: {
              scope: :club_id,
              message: "já pertence a este clube"
            }

end
