class Club < ApplicationRecord
  has_many :club_memberships, dependent: :destroy

  has_many :members,
           through: :club_memberships,
           source: :user

  has_one :owner_membership,
          -> { where(role: "owner") },
          class_name: "ClubMembership"

  has_one :owner,
          through: :owner_membership,
          source: :user

  validates :name, presence: true
end
