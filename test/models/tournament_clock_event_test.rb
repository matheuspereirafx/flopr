require "test_helper"

class TournamentClockEventTest < ActiveSupport::TestCase
  def setup
    @tournament = create_tournament(club: create_club)
    @from_level = @tournament.blind_levels.first
    @to_level = @tournament.blind_levels.second
  end

  test "belongs to the tournament and both transition levels" do
    assert_equal :belongs_to,
                 TournamentClockEvent.reflect_on_association(:tournament).macro
    assert_equal :belongs_to,
                 TournamentClockEvent.reflect_on_association(:from_blind_level).macro
    assert_equal :belongs_to,
                 TournamentClockEvent.reflect_on_association(:to_blind_level).macro
  end

  test "accepts an automatic level advance event" do
    event = TournamentClockEvent.new(
      tournament: @tournament,
      from_blind_level: @from_level,
      to_blind_level: @to_level,
      kind: :automatic_level_advanced,
      occurred_at: Time.current
    )

    assert event.valid?
  end

  test "accepts a manual level advance event" do
    event = TournamentClockEvent.new(
      tournament: @tournament,
      from_blind_level: @from_level,
      to_blind_level: @to_level,
      kind: :manual_level_advanced,
      occurred_at: Time.current
    )

    assert event.valid?
  end

  test "requires an occurrence time" do
    event = TournamentClockEvent.new(
      tournament: @tournament,
      from_blind_level: @from_level,
      to_blind_level: @to_level,
      kind: :automatic_level_advanced
    )

    assert_not event.valid?
    assert event.errors.of_kind?(:occurred_at, :blank)
  end

  test "accepts only supported event kinds" do
    event = TournamentClockEvent.new(
      tournament: @tournament,
      from_blind_level: @from_level,
      to_blind_level: @to_level,
      kind: "unsupported_event",
      occurred_at: Time.current
    )

    assert_not event.valid?
    assert event.errors.of_kind?(:kind, :inclusion)
  end

  test "rejects transition levels from another tournament" do
    other_tournament = create_tournament(club: create_club)
    event = TournamentClockEvent.new(
      tournament: @tournament,
      from_blind_level: @from_level,
      to_blind_level: other_tournament.blind_levels.first,
      kind: :automatic_level_advanced,
      occurred_at: Time.current
    )

    assert_not event.valid?
    assert_includes event.errors[:to_blind_level], "deve pertencer ao torneio"
  end
end
