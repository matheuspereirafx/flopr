require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  def setup
    @club = Club.create!(name: "Poker House")
  end

  test "belongs to club" do
    assert_equal :belongs_to, Tournament.reflect_on_association(:club).macro
  end

  test "has an optional cover attachment" do
    assert_equal :has_one_attached, Tournament.reflect_on_attachment(:cover).macro
  end

  test "rejects covers larger than 8 MB" do
    tournament = build_tournament
    tournament.cover.attach(
      io: StringIO.new("0" * (Tournament::COVER_MAX_SIZE + 1)),
      filename: "cover.png",
      content_type: "image/png"
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:cover], "deve ter no máximo 8 MB"
  end

  test "rejects non-image covers" do
    tournament = build_tournament
    tournament.cover.attach(
      io: StringIO.new("not an image"),
      filename: "cover.pdf",
      content_type: "application/pdf"
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:cover], "deve ser uma imagem JPEG, PNG ou WebP"
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
    user = User.create!(name: "Player", username: "player", email: "player@example.com", password: "password123")
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

  test "live scope includes posted tournaments with an active or paused clock" do
    running = create_tournament(status: :posted, name: "Running", with_buy_in: true)
    paused = create_tournament(status: :posted, name: "Paused", with_buy_in: true)
    draft = create_tournament(name: "Draft")
    finished = create_tournament(status: :finished, name: "Finished")

    TournamentClockState.create_initial_for!(running).update!(status: :running)
    TournamentClockState.create_initial_for!(paused).update!(status: :paused)
    TournamentClockState.create_initial_for!(draft).update!(status: :running)
    TournamentClockState.create_initial_for!(finished).update!(status: :overtime)

    assert_equal ["Paused", "Running"].sort, Tournament.live.pluck(:name).sort
  end

  test "upcoming scope includes only future posted tournaments ordered by date" do
    later = create_tournament(status: :posted, name: "Later", starts_at: 2.days.from_now, with_buy_in: true)
    sooner = create_tournament(status: :posted, name: "Sooner", starts_at: 1.hour.from_now, with_buy_in: true)
    create_tournament(status: :draft, name: "Draft", starts_at: 1.hour.from_now)
    create_tournament(status: :posted, name: "Past", starts_at: 1.hour.ago, with_buy_in: true)

    assert_equal [sooner, later], Tournament.upcoming.to_a
  end

  test "allows only forward tournament status transitions" do
    tournament = create_tournament(name: "Status Flow")

    tournament.status = :posted
    assert tournament.valid?
    tournament.save!

    tournament.status = :finished
    assert tournament.valid?
    tournament.save!
  end

  test "rejects backwards tournament status transitions" do
    posted = create_tournament(status: :posted, name: "Posted Status", with_buy_in: true)
    finished = create_tournament(status: :finished, name: "Finished Status")

    posted.status = :draft
    assert_not posted.valid?
    assert_includes posted.errors[:status], "não pode voltar para um estado anterior"

    finished.status = :posted
    assert_not finished.valid?
    assert_includes finished.errors[:status], "não pode voltar para um estado anterior"

    finished.status = :draft
    assert_not finished.valid?
  end

  test "is invalid when removal leaves fewer than five blind levels" do
    tournament = build_tournament
    tournament.blind_levels.last.mark_for_destruction

    assert_not tournament.valid?
    assert_includes tournament.errors[:blind_levels], "deve possuir no mínimo 5 níveis"
  end

  private

  def create_tournament(attributes = {})
    with_buy_in = attributes.delete(:with_buy_in)
    tournament = build_tournament(attributes)
    tournament.charge_options.build(kind: :buy_in, active: true, amount: 50, chip_amount: 10_000) if with_buy_in
    tournament.save!
    tournament
  end

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
