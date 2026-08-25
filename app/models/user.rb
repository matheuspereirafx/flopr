class User < ApplicationRecord
  attribute :terms, :boolean, default: false

  has_many :club_memberships, dependent: :destroy
  has_many :tournament_registrations, dependent: :destroy

  has_many :clubs,
           through: :club_memberships

  has_many :owner_club_memberships,
           -> { where(role: "owner") },
           class_name: "ClubMembership"

  has_many :owned_clubs,
           through: :owner_club_memberships,
           source: :club

  validates :username, presence: true, on: :create
  validates :username,
            format: { with: /\A[a-zA-Z0-9_.]+\z/, allow_nil: true },
            uniqueness: { allow_nil: true }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
