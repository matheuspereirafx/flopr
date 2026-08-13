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

  after_update_commit :broadcast_state_change

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

    return refresh_running!(at: at, persist: false) if elapsed_seconds(at) < remaining_seconds

    with_lock { refresh_running!(at: at, persist: true) }
  end

  def overtime_seconds(at: Time.current)
    elapsed_seconds = overtime_elapsed_seconds
    return elapsed_seconds unless overtime?

    elapsed_seconds + (at - overtime_started_at).floor
  end

  private

  def refresh_running!(at:, persist:)
    return self unless running?

    if elapsed_seconds(at) < remaining_seconds
      attributes = {
        remaining_seconds: remaining_seconds - elapsed_seconds(at),
        started_at: at
      }

      return persist ? update!(attributes) : assign_attributes(attributes)
    end

    advance_expired_levels!(at: at)
  end

  def advance_expired_levels!(at:)
    transition_at = started_at + remaining_seconds.seconds

    loop do
      next_blind_level = tournament.blind_levels.find_by("level > ?", current_blind_level.level)
      return enter_overtime!(at: transition_at) if next_blind_level.blank?

      TournamentClockEvent.create!(
        tournament: tournament,
        from_blind_level: current_blind_level,
        to_blind_level: next_blind_level,
        kind: :automatic_level_advanced,
        occurred_at: transition_at
      )

      self.current_blind_level = next_blind_level
      self.remaining_seconds = next_blind_level.duration_minutes * 60
      self.started_at = transition_at

      if elapsed_seconds(at) < remaining_seconds
        return update!(
          remaining_seconds: remaining_seconds - elapsed_seconds(at),
          started_at: at
        )
      end

      transition_at = started_at + remaining_seconds.seconds
    end
  end

  def current_blind_level_belongs_to_tournament
    return if current_blind_level.blank? || tournament.blank?
    return if current_blind_level.tournament_id == tournament_id

    errors.add(:current_blind_level, "deve pertencer ao torneio")
  end

  def elapsed_seconds(at)
    (at - started_at).floor
  end

  def broadcast_state_change
    broadcast_replace_to [tournament, :clock],
                         target: "tournament-clock-state-#{tournament_id}",
                         partial: "tournament_clocks/state",
                         locals: { clock_state: self }
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
