class Club < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :club_memberships, dependent: :destroy

  has_many :members,
           through: :club_memberships,
           source: :user

  validates :name, presence: true
end
