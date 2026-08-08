require "test_helper"

class BlindLevelTest < ActiveSupport::TestCase
  def setup
    @blind_level = BlindLevel.new(
      tournament: build_tournament,
      level: 1,
      duration_minutes: 15,
      small_blind: 100,
      big_blind: 200,
      ante: 0
    )
  end

  test "is valid with positive blinds, duration, and zero ante" do
    assert @blind_level.valid?
  end

  test "requires a positive small blind" do
    @blind_level.small_blind = 0

    assert_not @blind_level.valid?
    assert @blind_level.errors.of_kind?(:small_blind, :greater_than)
  end

  test "requires a big blind greater than or equal to small blind" do
    @blind_level.big_blind = 50

    assert_not @blind_level.valid?
    assert_includes @blind_level.errors[:big_blind], "deve ser maior ou igual ao small blind"
  end

  test "converts a blank ante to zero" do
    @blind_level.ante = ""

    assert @blind_level.valid?
    assert_equal 0, @blind_level.ante
  end

  test "does not accept a negative ante" do
    @blind_level.ante = -1

    assert_not @blind_level.valid?
    assert @blind_level.errors.of_kind?(:ante, :greater_than_or_equal_to)
  end

  test "requires a positive duration" do
    @blind_level.duration_minutes = 0

    assert_not @blind_level.valid?
    assert @blind_level.errors.of_kind?(:duration_minutes, :greater_than)
  end

  private

  def build_tournament
    club = Club.create!(name: "Poker House #{SecureRandom.uuid}")

    Tournament.new(
      club: club,
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :posted
    )
  end
end
