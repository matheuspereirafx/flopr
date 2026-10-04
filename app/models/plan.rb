class Plan < ApplicationRecord
  has_many :club_subscriptions, dependent: :restrict_with_exception

  enum :billing_period, {
    monthly: "monthly",
    yearly: "yearly"
  }

  scope :active, -> { where(active: true) }

  validates :name, :description, :price, :billing_period, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
end
