class TournamentClockEvent < ApplicationRecord
  belongs_to :tournament
  belongs_to :from_blind_level, class_name: "BlindLevel"
  belongs_to :to_blind_level, class_name: "BlindLevel"

  enum :kind, {
    automatic_level_advanced: "automatic_level_advanced"
  }, validate: true

  validates :occurred_at, presence: true

  validate :transition_levels_belong_to_tournament

  private

  def transition_levels_belong_to_tournament
    validate_level_tournament(:from_blind_level)
    validate_level_tournament(:to_blind_level)
  end

  def validate_level_tournament(attribute)
    blind_level = public_send(attribute)
    return if blind_level.blank? || tournament.blank?
    return if blind_level.tournament_id == tournament_id

    errors.add(attribute, "deve pertencer ao torneio")
  end
end
