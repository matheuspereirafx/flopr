class Tournament < ApplicationRecord
  belongs_to :club
  has_many :blind_levels, dependent: :destroy

  accepts_nested_attributes_for :blind_levels

  validates :blind_levels, length: { minimum: 5 }

  enum :status, {
    draft: "draft",
    posted: "posted",
    finished: "finished"
  }

  validates :name, presence: true
  validates :location, presence: true
  validates :max_players, presence: true
  validates :starts_at, presence: true
  validates :status, presence: true
end
