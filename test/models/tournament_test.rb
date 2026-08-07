require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  def setup
    @club = Club.create!(name: "Poker House")
  end

  test "belongs to club" do
    association = Tournament.reflect_on_association(:club)

    assert_equal :belongs_to, association.macro
  end

  test "is valid with required attributes" do
    tournament = build_tournament

    assert tournament.valid?
  end

  test "is invalid without club" do
    tournament = build_tournament(club: nil)

    assert_not tournament.valid?
    assert_not_empty tournament.errors[:club]
  end

  test "is invalid without name" do
    tournament = build_tournament(name: nil)

    assert_not tournament.valid?
    assert tournament.errors.of_kind?(:name, :blank)
  end

  test "is invalid without location" do
    tournament = build_tournament(location: nil)

    assert_not tournament.valid?
    assert tournament.errors.of_kind?(:location, :blank)
  end

  test "is invalid without max players" do
    tournament = build_tournament(max_players: nil)

    assert_not tournament.valid?
    assert tournament.errors.of_kind?(:max_players, :blank)
  end

  test "is invalid without starts at" do
    tournament = build_tournament(starts_at: nil)

    assert_not tournament.valid?
    assert tournament.errors.of_kind?(:starts_at, :blank)
  end

  test "is invalid without status" do
    tournament = build_tournament(status: nil)

    assert_not tournament.valid?
    assert tournament.errors.of_kind?(:status, :blank)
  end

  test "defaults status to posted" do
    tournament = build_tournament

    assert_equal "posted", tournament.status
    assert tournament.posted?
  end

  test "defines the expected statuses" do
    assert_equal({
      "draft" => "draft",
      "posted" => "posted",
      "finished" => "finished"
    }, Tournament.statuses)
  end

  private

  def build_tournament(attributes = {})
  defaults = {
    club: @club,
    name: "Friday Poker Night",
    location: "Rua das Flores, 123",
    max_players: 24,
    starts_at: 2.days.from_now,
    blind_levels_attributes: blind_levels_attributes
  }

  Tournament.new(defaults.merge(attributes))
  end

  def blind_levels_attributes
    5.times.map do |index|
      {
        level: index + 1,
        duration_minutes: 15,
        small_blind: (index + 1) * 100,
        big_blind: (index + 1) * 200,
        ante: 0
      }
    end

  end
end
