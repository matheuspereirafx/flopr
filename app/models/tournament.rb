class Tournament < ApplicationRecord
  belongs_to :club

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
