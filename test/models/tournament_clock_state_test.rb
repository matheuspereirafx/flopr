require "test_helper"

class TournamentClockStateTest < ActiveSupport::TestCase
  def setup
    @tournament = create_tournament(club: create_club)
    @first_level = @tournament.blind_levels.first
  end

  test "belongs to a tournament and its current blind level" do
    assert_equal :belongs_to,
                 TournamentClockState.reflect_on_association(:tournament).macro
    assert_equal :belongs_to,
                 TournamentClockState.reflect_on_association(:current_blind_level).macro
  end

  test "is valid with an initial clock state" do
    state = build_clock_state

    assert state.valid?
  end

  test "requires a unique clock state for each tournament" do
    build_clock_state.save!
    duplicate = build_clock_state

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tournament_id], "já possui relógio"
  end

  test "requires the current blind level to belong to its tournament" do
    other_tournament = create_tournament(club: create_club)
    state = build_clock_state(current_blind_level: other_tournament.blind_levels.first)

    assert_not state.valid?
    assert_includes state.errors[:current_blind_level], "deve pertencer ao torneio"
  end

  test "does not accept a negative remaining time" do
    state = build_clock_state(remaining_seconds: -1)

    assert_not state.valid?
    assert state.errors.of_kind?(:remaining_seconds, :greater_than_or_equal_to)
  end

  test "accepts only the approved statuses" do
    state = build_clock_state(status: "invalid")

    assert_not state.valid?
    assert state.errors.of_kind?(:status, :inclusion)
  end

  test "starts with the first level duration in seconds" do
    state = TournamentClockState.create_initial_for!(@tournament)

    assert_equal @first_level, state.current_blind_level
    assert_equal @first_level.duration_minutes * 60, state.remaining_seconds
    assert state.not_started?
  end

  test "creating the initial state twice returns the existing state" do
    first_state = TournamentClockState.create_initial_for!(@tournament)

    assert_no_difference "TournamentClockState.count" do
      second_state = TournamentClockState.create_initial_for!(@tournament)
      assert_equal first_state, second_state
    end
  end

  test "is destroyed when its tournament is destroyed" do
    TournamentClockState.create_initial_for!(@tournament)

    assert_difference "TournamentClockState.count", -1 do
      @tournament.destroy!
    end
  end

  test "starting records the timestamp and changes status to running" do
    state = build_clock_state
    now = Time.zone.local(2026, 8, 12, 20, 0, 0)

    state.start!(at: now)

    assert state.running?
    assert_equal now, state.started_at
    assert_nil state.paused_at
  end

  test "pausing persists the elapsed remaining time" do
    state = build_clock_state(status: :running, started_at: 2.minutes.ago, remaining_seconds: 900)

    state.pause!(at: Time.current)

    assert state.paused?
    assert_in_delta 780, state.remaining_seconds, 2
    assert_not_nil state.paused_at
  end

  test "resuming preserves the paused time instead of restarting the level" do
    state = build_clock_state(status: :paused, remaining_seconds: 780, paused_at: Time.current)
    now = Time.zone.local(2026, 8, 12, 20, 0, 0)

    state.resume!(at: now)

    assert state.running?
    assert_equal 780, state.remaining_seconds
    assert_equal now, state.started_at
    assert_nil state.paused_at
  end

  test "enters overtime at the last level and continues counting elapsed time" do
    last_level = @tournament.blind_levels.last
    state = build_clock_state(
      current_blind_level: last_level,
      status: :running,
      remaining_seconds: 1,
      started_at: 2.seconds.ago
    )

    state.refresh!(at: Time.current)

    assert state.overtime?
    assert_equal last_level, state.current_blind_level
    assert_not_nil state.overtime_started_at
    assert_operator state.overtime_seconds(at: 5.seconds.from_now), :>=, 5
  end

  private

  def build_clock_state(attributes = {})
    defaults = {
      tournament: @tournament,
      current_blind_level: @first_level,
      remaining_seconds: @first_level.duration_minutes * 60,
      status: :not_started
    }

    TournamentClockState.new(defaults.merge(attributes))
  end
end
