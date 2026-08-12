class TournamentClockState < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :tournament
  belongs_to :current_blind_level,
             class_name: "BlindLevel"

  enum :status, {
    not_started: "not_started",
    running: "running",
    paused: "paused",
    overtime: "overtime",
    finished: "finished"
  }, validate: true

  validates :tournament_id,
            uniqueness: {
              message: "já possui relógio"
            }
  validates :remaining_seconds,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }
  validates :overtime_elapsed_seconds,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validate :current_blind_level_belongs_to_tournament

  class << self
    def create_initial_for!(tournament)
      tournament.with_lock do
        tournament.clock_state || create!(
          tournament: tournament,
          current_blind_level: tournament.blind_levels.first!,
          remaining_seconds: tournament.blind_levels.first.duration_minutes * 60,
          status: :not_started
        )
      end
    end
  end

  def start!(at: Time.current)
    raise InvalidTransition unless not_started?

    update!(
      status: :running,
      started_at: at,
      paused_at: nil
    )
  end

  def pause!(at: Time.current)
    refresh!(at: at) if running?

    if overtime?
      pause_overtime!(at: at)
    elsif running?
      update!(status: :paused, paused_at: at, started_at: nil)
    else
      raise InvalidTransition
    end
  end

  def resume!(at: Time.current)
    raise InvalidTransition unless paused?

    if overtime_started_at.present?
      update!(status: :overtime, started_at: nil, paused_at: nil, overtime_started_at: at)
    else
      update!(status: :running, started_at: at, paused_at: nil)
    end
  end

  def refresh!(at: Time.current)
    return self unless running?

    elapsed_seconds = (at - started_at).floor
    if elapsed_seconds < remaining_seconds
      return update!(
        remaining_seconds: remaining_seconds - elapsed_seconds,
        started_at: at
      )
    end

    if current_blind_level == tournament.blind_levels.last
      enter_overtime!(at: started_at + remaining_seconds.seconds)
    else
      update!(remaining_seconds: 0, started_at: at)
    end
  end

  def overtime_seconds(at: Time.current)
    elapsed_seconds = overtime_elapsed_seconds
    return elapsed_seconds unless overtime?

    elapsed_seconds + (at - overtime_started_at).floor
  end

  private

  def current_blind_level_belongs_to_tournament
    return if current_blind_level.blank? || tournament.blank?
    return if current_blind_level.tournament_id == tournament_id

    errors.add(:current_blind_level, "deve pertencer ao torneio")
  end

  def enter_overtime!(at:)
    update!(
      status: :overtime,
      remaining_seconds: 0,
      started_at: nil,
      overtime_started_at: at
    )
  end

  def pause_overtime!(at:)
    elapsed_seconds = overtime_seconds(at: at)

    update!(
      status: :paused,
      started_at: nil,
      paused_at: at,
      overtime_elapsed_seconds: elapsed_seconds
    )
  end
end
