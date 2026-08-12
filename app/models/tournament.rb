class Tournament < ApplicationRecord
  MINIMUM_BLIND_LEVELS = 5

  attr_accessor :blind_levels_count

  belongs_to :club

  has_many :blind_levels,
           -> { order(:level) },
           dependent: :destroy

  accepts_nested_attributes_for :blind_levels,
                                allow_destroy: true

  enum :status, {
    draft: "draft",
    posted: "posted",
    finished: "finished"
  }

  validates :name, :location, :max_players, :starts_at, :status, presence: true

  validate :has_minimum_blind_levels
  validate :blind_levels_are_sequential
  validate :blind_levels_have_same_duration
  validate :blind_levels_count_matches_structure

  before_validation :renumber_blind_levels

  private

  def active_blind_levels
    blind_levels.reject(&:marked_for_destruction?)
  end

  def has_minimum_blind_levels
    return if active_blind_levels.size >= MINIMUM_BLIND_LEVELS

    errors.add(
      :blind_levels,
      "deve possuir no mínimo #{MINIMUM_BLIND_LEVELS} níveis"
    )
  end

  def blind_levels_are_sequential
    levels = active_blind_levels.map(&:level)

    return if levels == (1..active_blind_levels.size).to_a

    errors.add(:blind_levels, "devem estar numerados sequencialmente")
  end

  def blind_levels_have_same_duration
    durations = active_blind_levels.map(&:duration_minutes).uniq

    return if durations.size <= 1

    errors.add(:blind_levels, "devem possuir a mesma duração")
  end

  def blind_levels_count_matches_structure
    return if blind_levels_count.blank?
    return if blind_levels_count.to_i == active_blind_levels.size

    errors.add(
      :blind_levels_count,
      "deve ser igual à quantidade de níveis configurados"
    )
  end

  def renumber_blind_levels
    active_blind_levels.each_with_index do |blind_level, index|
      blind_level.level = index + 1
    end
  end
end
