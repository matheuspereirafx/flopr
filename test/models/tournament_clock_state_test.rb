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

  test "refreshing a running level without expiration does not persist a clock update" do
    state = build_clock_state(
      status: :running,
      started_at: 2.minutes.ago,
      remaining_seconds: 900
    )
    state.save!

    assert_no_changes -> { TournamentClockState.find(state.id).attributes } do
      state.refresh!(at: Time.current)
    end

    assert_in_delta 780, state.remaining_seconds, 2
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

  test "automatically advances to the next level with its configured duration" do
    second_level = @tournament.blind_levels.second
    finished_at = Time.zone.local(2026, 8, 12, 20, 0, 0)
    state = build_clock_state(
      status: :running,
      remaining_seconds: 1,
      started_at: 1.second.before(finished_at)
    )

    assert_difference "TournamentClockEvent.count", 1 do
      state.refresh!(at: finished_at)
    end

    assert state.running?
    assert_equal second_level, state.current_blind_level
    assert_equal second_level.duration_minutes * 60, state.remaining_seconds
    assert_equal finished_at, state.started_at

    event = TournamentClockEvent.last
    assert_equal @first_level, event.from_blind_level
    assert_equal second_level, event.to_blind_level
    assert event.automatic_level_advanced?
    assert_equal finished_at, event.occurred_at
  end

  test "automatically advances through every expired level and records each transition" do
    levels = @tournament.blind_levels.to_a
    started_at = Time.zone.local(2026, 8, 12, 20, 0, 0)
    refreshed_at = started_at + 46.minutes
    state = build_clock_state(
      status: :running,
      remaining_seconds: 15.minutes.to_i,
      started_at: started_at
    )

    assert_difference "TournamentClockEvent.count", 3 do
      state.refresh!(at: refreshed_at)
    end

    assert state.running?
    assert_equal levels.fourth, state.current_blind_level
    assert_equal 14.minutes.to_i, state.remaining_seconds
    assert_equal refreshed_at, state.started_at

    events = TournamentClockEvent.order(:occurred_at).last(3)
    assert_equal [levels.first, levels.second, levels.third], events.map(&:from_blind_level)
    assert_equal [levels.second, levels.third, levels.fourth], events.map(&:to_blind_level)
    assert_equal [
      started_at + 15.minutes,
      started_at + 30.minutes,
      started_at + 45.minutes
    ], events.map(&:occurred_at)
  end

  test "does not advance or register an event while paused" do
    paused_at = Time.zone.local(2026, 8, 12, 20, 0, 0)
    state = build_clock_state(
      status: :paused,
      remaining_seconds: 1,
      paused_at: paused_at
    )
    state.save!

    assert_no_difference "TournamentClockEvent.count" do
      state.refresh!(at: 1.hour.after(paused_at))
    end

    assert_equal @first_level, state.current_blind_level
    assert_equal 1, state.remaining_seconds
    assert state.paused?
  end

  test "enters overtime without recording an advance when the last level ends" do
    last_level = @tournament.blind_levels.last
    finished_at = Time.zone.local(2026, 8, 12, 20, 0, 0)
    state = build_clock_state(
      current_blind_level: last_level,
      status: :running,
      remaining_seconds: 1,
      started_at: 1.second.before(finished_at)
    )

    assert_no_difference "TournamentClockEvent.count" do
      state.refresh!(at: finished_at)
    end

    assert state.overtime?
    assert_equal last_level, state.current_blind_level
    assert_equal 0, state.remaining_seconds
    assert_equal finished_at, state.overtime_started_at
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
