require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @owner = User.create!(
      email: "owner@example.com",
      password: "password123",
      name: "Owner",
      username: "owner"
    )
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    @admin = User.create!(email: "admin@example.com", password: "password123", name: "Admin", username: "admin")
    @dealer = User.create!(email: "dealer@example.com", password: "password123", name: "Dealer", username: "dealer")
    @player = User.create!(email: "player@example.com", password: "password123", name: "Player", username: "player")
    ClubMembership.create!(user: @admin, club: @club, role: :admin)
    ClubMembership.create!(user: @dealer, club: @club, role: :dealer)
    ClubMembership.create!(user: @player, club: @club, role: :player)
  end

  test "does not prefetch the create club link on clubs index" do
    sign_in @owner
    get clubs_path

    assert_response :success
    assert_select ".clubs-header a[data-turbo-prefetch='false'][href='#{new_club_path}']", count: 1
  end

  test "owner, admin and dealer can view the club but player cannot" do
    [@owner, @admin, @dealer].each do |user|
      sign_in user
      get club_path(@club)

      assert_response :success
      sign_out user
    end

    sign_in @player
    get club_path(@club)

    assert_response :forbidden
  end

  test "shows the configured buy in amount in the tournament card" do
    tournament = create_tournament
    tournament.charge_options.create!(
      kind: :buy_in,
      active: true,
      amount: 125.5,
      chip_amount: 10_000
    )

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select ".tournament-card__information-value--highlight", "R$ 125,50"
    assert_not_select ".tournament-card__information-value--highlight", "R$ 250"
    assert_select ".tournament-card__link[data-turbo-prefetch='false']", count: 1
  end

  test "shows the number of active player memberships in the club hero" do
    second_player = User.create!(
      email: "second-player@example.com",
      password: "password123",
      name: "Second Player",
      username: "second_player"
    )
    ClubMembership.create!(user: second_player, club: @club, role: :player)

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select ".club-show-hero__players-count", "2"
  end

  test "does not prefetch the create tournament link on club show" do
    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select ".club-show__create-tournament[data-turbo-prefetch='false']", count: 1
  end

  test "shows buy in as pending when the tournament has no financial configuration" do
    create_tournament

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select ".tournament-card__information-value--highlight", "A definir"
  end

  test "shows confirmed registrations and tournament capacity in the tournament card" do
    tournament = create_tournament
    confirmed_player = User.create!(
      email: "confirmed@example.com",
      password: "password123",
      name: "Confirmed",
      username: "confirmed"
    )
    pending_player = User.create!(
      email: "pending@example.com",
      password: "password123",
      name: "Pending",
      username: "pending"
    )
    TournamentRegistration.create!(
      tournament: tournament,
      user: confirmed_player,
      status: :confirmed
    )
    TournamentRegistration.create!(
      tournament: tournament,
      user: pending_player,
      status: :pending
    )

    sign_in @owner
    get club_path(@club)

    assert_select ".tournament-card__players-value strong", "1"
    assert_select ".tournament-card__players-value span", "/ 24"
  end

  test "orders live tournaments before other tournaments and exposes filter data" do
    create_tournament(name: "Soon", starts_at: 1.hour.from_now)
    live = create_tournament(name: "Live", starts_at: 2.days.from_now)
    live.charge_options.create!(kind: :buy_in, active: true, amount: 50, chip_amount: 10_000)
    live.update!(status: :posted)
    TournamentClockState.create_initial_for!(live).update!(status: :running)

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_operator response.body.index("Live"), :<, response.body.index("Soon")
    assert_select ".tournament-card[data-tournament-status='posted'][data-clock-status='running']", count: 1
    assert_select ".tournament-card__status--posted", text: /Publicado/, count: 1
    assert_select ".tournament-card__status--clock.tournament-card__status--running", text: /Ao vivo/, count: 1
    assert_select ".club-events__filter[data-filter='live']", count: 1
    assert_select ".club-events__filter[data-filter='upcoming']", count: 1
  end

  private

  def create_tournament(attributes = {})
    tournament = @club.tournaments.build(
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft,
      **attributes
    )

    5.times do |index|
      level = index + 1
      tournament.blind_levels.build(
        level: level,
        duration_minutes: 15,
        small_blind: level * 100,
        big_blind: level * 200,
        ante: 0
      )
    end

    tournament.save!
    tournament
  end
end
