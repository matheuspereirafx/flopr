require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  def setup
    @club = Club.create!(name: "Poker House")
  end

  test "belongs to club" do
    assert_equal :belongs_to, Tournament.reflect_on_association(:club).macro
  end

  test "has tournament registrations" do
    assert_equal :has_many,
                 Tournament.reflect_on_association(:tournament_registrations).macro
  end

  test "generates a unique invite token when created" do
    first_tournament = build_tournament
    second_tournament = build_tournament(name: "Saturday Poker Night")

    first_tournament.save!
    second_tournament.save!

    assert_predicate first_tournament.invite_token, :present?
    assert_not_equal first_tournament.invite_token, second_tournament.invite_token
  end

  test "invite link is unavailable when confirmed registrations reach capacity" do
    tournament = build_tournament(max_players: 1)
    tournament.save!
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")
    TournamentRegistration.create!(tournament: tournament, user: user, status: :confirmed)

    assert_predicate tournament, :capacity_reached?
    assert_not_predicate tournament, :invite_link_valid?
  end

  test "is valid with five sequential blind levels of the same duration" do
    assert build_tournament.valid?
  end

  test "does not allow a tournament name already used with different casing" do
    build_tournament.save!
    other_club = Club.create!(name: "Another Poker House")
    tournament = build_tournament(
      club: other_club,
      name: "FRIDAY POKER NIGHT"
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:name], "já está em uso"
  end

  test "is invalid with fewer than five blind levels" do
    tournament = build_tournament(blind_levels_attributes: blind_levels_attributes.take(4))

    assert_not tournament.valid?
    assert_includes tournament.errors[:blind_levels], "deve possuir no mínimo 5 níveis"
  end

  test "renumbers blind levels sequentially before validation" do
    attributes = blind_levels_attributes.map.with_index do |attributes, index|
      attributes.merge(level: 10 - index)
    end
    tournament = build_tournament(blind_levels_attributes: attributes)

    assert tournament.valid?
    assert_equal [1, 2, 3, 4, 5], tournament.blind_levels.map(&:level)
  end

  test "is invalid when blind level durations differ" do
    attributes = blind_levels_attributes
    attributes.last[:duration_minutes] = 30
    tournament = build_tournament(blind_levels_attributes: attributes)

    assert_not tournament.valid?
    assert_includes tournament.errors[:blind_levels], "devem possuir a mesma duração"
  end

  test "is invalid when selected count differs from active blind levels" do
    tournament = build_tournament
    tournament.blind_levels_count = 6

    assert_not tournament.valid?
    assert_includes tournament.errors[:blind_levels_count],
                    "deve ser igual à quantidade de níveis configurados"
  end

  test "allows removal while at least five blind levels remain" do
    tournament = build_tournament(blind_levels_attributes: blind_levels_attributes(6))
    tournament.blind_levels.last.mark_for_destruction

    assert tournament.valid?
  end

  test "posted tournament requires only an active buy in" do
    tournament = build_tournament(status: :posted)

    assert_not tournament.valid?
    assert_includes tournament.errors[:base], "buy-in deve estar configurado"
    assert_not_includes tournament.errors[:base], "rebuy deve estar configurado"
  end

  test "posted tournament is valid with buy in and no rebuy" do
    tournament = build_tournament(status: :posted)
    tournament.charge_options.build(
      kind: :buy_in,
      active: true,
      amount: 50,
      chip_amount: 10_000
    )

    assert tournament.valid?
  end

  test "draft tournament can be saved before financial configuration" do
    tournament = build_tournament(status: :draft)

    assert tournament.valid?
  end

  test "is invalid when removal leaves fewer than five blind levels" do
    tournament = build_tournament
    tournament.blind_levels.last.mark_for_destruction

    assert_not tournament.valid?
    assert_includes tournament.errors[:blind_levels], "deve possuir no mínimo 5 níveis"
  end

  private

  def build_tournament(attributes = {})
    defaults = {
      club: @club,
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft,
      blind_levels_attributes: blind_levels_attributes
    }

    Tournament.new(defaults.merge(attributes))
  end

  def blind_levels_attributes(count = 5)
    count.times.map do |index|
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
