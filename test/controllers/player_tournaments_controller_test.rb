require "test_helper"

class PlayerTournamentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @other_club = Club.create!(name: "Other Poker House")
    @player = create_user("player@example.com")
    @outsider = create_user("outsider@example.com")

    create_membership(@player, @club, :player)
    create_membership(@outsider, @other_club, :owner)
  end

  test "authenticated users can view upcoming tournaments from every club they belong to" do
    second_membership_club = Club.create!(name: "Second Poker House")
    create_membership(@player, second_membership_club, :dealer)
    earliest = create_tournament(@club, name: "Earliest Tournament", starts_at: 1.day.from_now)
    latest = create_tournament(second_membership_club, name: "Latest Tournament", starts_at: 3.days.from_now)
    create_tournament(@other_club, name: "Private Tournament", starts_at: 2.days.from_now)

    sign_in @player
    get player_tournaments_path

    assert_response :success
    assert_select ".player-tournaments-page__section:nth-of-type(1) .club-events__title",
                  text: "Próximos torneios"
    assert_select ".player-tournaments-page__section:nth-of-type(1) .tournament-card__title", 2
    assert_operator response.body.index(earliest.name), :<, response.body.index(latest.name)
    assert_not_includes response.body, "Private Tournament"
  end

  test "my tournaments only contains registrations belonging to the current user" do
    registered_tournament = create_tournament(@club, name: "Registered Tournament", starts_at: 4.days.from_now)
    other_tournament = create_tournament(@club, name: "Other Registration", starts_at: 5.days.from_now)
    TournamentRegistration.create!(tournament: registered_tournament, user: @player, status: :pending)
    TournamentRegistration.create!(tournament: other_tournament, user: @outsider, status: :confirmed)

    sign_in @player
    get player_tournaments_path

    assert_response :success
    assert_select ".player-tournaments-page__section:nth-of-type(2) .club-events__title",
                  text: "Meus torneios"
    assert_select ".player-tournaments-page__section:nth-of-type(2)", text: /Registered Tournament/
    assert_select ".player-tournaments-page__section:nth-of-type(2)", text: /Other Registration/, count: 0
  end

  test "unauthenticated users are redirected to login" do
    get player_tournaments_path

    assert_redirected_to new_user_session_path
  end

  private

  def create_user(email)
    User.create!(
      email: email,
      password: "password123",
      name: email.split("@").first,
      username: email.split("@").first
    )
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_tournament(club, attributes)
    tournament = club.tournaments.build(
      {
        location: "Rua das Flores, 123",
        max_players: 24,
        status: :draft
      }.merge(attributes)
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
