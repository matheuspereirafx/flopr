class User < ApplicationRecord
  has_many :club_memberships, dependent: :destroy

  has_many :clubs,
           through: :club_memberships

  has_many :owner_club_memberships,
           -> { where(role: "owner") },
           class_name: "ClubMembership"

  has_many :owned_clubs,
           through: :owner_club_memberships,
           source: :club

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
