require "test_helper"

class TournamentRegistrationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = create_club(name: "Poker House")
    @other_club = create_club(name: "Other Poker House")
    @tournament = create_tournament(club: @club, name: "Friday Registration")
    @other_tournament = create_tournament(club: @other_club, name: "Other Registration")

    @owner = create_user(email: "owner@example.com")
    @admin = create_user(email: "admin@example.com")
    @dealer = create_user(email: "dealer@example.com")
    @player = create_user(email: "player@example.com")
    @outsider = create_user(email: "outsider@example.com")

    create_membership(user: @owner, club: @club, role: :owner)
    create_membership(user: @admin, club: @club, role: :admin)
    create_membership(user: @dealer, club: @club, role: :dealer)
    create_membership(user: @player, club: @club, role: :player)
    create_membership(user: @outsider, club: @other_club, role: :owner)

    TournamentRegistration.create!(
      tournament: @tournament,
      user: @player,
      status: :confirmed
    )
  end

  test "unauthenticated user is redirected to sign in" do
    get registrations_path

    assert_redirected_to new_user_session_path
  end

  test "owner, admin, dealer and participating player can view registrations" do
    [@owner, @admin, @dealer, @player].each do |user|
      sign_in user

      get registrations_path

      assert_response :success
      sign_out user
    end
  end

  test "user without membership cannot view registrations" do
    sign_in @outsider

    get registrations_path

    assert_response :not_found
  end

  test "changing the club id cannot expose another club registrations" do
    sign_in @owner

    get registrations_path(club_id: @other_club.id, tournament_id: @other_tournament.id)

    assert_response :not_found
  end

  test "changing the tournament id cannot expose another club registrations" do
    sign_in @owner

    get registrations_path(club_id: @club.id, tournament_id: @other_tournament.id)

    assert_response :not_found
  end

  test "invalid ids return not found" do
    sign_in @owner

    get registrations_path(club_id: "invalid", tournament_id: "invalid")

    assert_response :not_found
  end

  test "index displays every registration name and status for the tournament" do
    pending_player = create_user(email: "pending@example.com")
    create_membership(user: pending_player, club: @club, role: :player)
    TournamentRegistration.create!(
      tournament: @tournament,
      user: pending_player,
      status: :pending
    )

    other_player = create_user(email: "other-tournament@example.com")
    TournamentRegistration.create!(
      tournament: @other_tournament,
      user: other_player,
      status: :confirmed
    )

    sign_in @player
    get registrations_path

    assert_response :success
    assert_includes response.body, @player.name
    assert_includes response.body, "@#{@player.username}"
    assert_includes response.body, "Você"
    assert_includes response.body, pending_player.name
    assert_includes response.body, "@#{pending_player.username}"
    assert_includes response.body, "pending"
    assert_includes response.body, "confirmed"
    assert_not_includes response.body, other_player.name
  end

  test "index displays an informative message when there are no registrations" do
    @tournament.tournament_registrations.delete_all
    sign_in @owner

    get registrations_path

    assert_response :success
    assert_includes response.body, "Nenhum jogador foi convidado para este torneio."
  end

  test "a new request reflects a changed registration status" do
    registration = @tournament.tournament_registrations.find_by!(user: @player)
    sign_in @owner

    registration.update!(status: :pending)
    get registrations_path

    assert_response :success
    assert_includes response.body, "pending"

    registration.update!(status: :confirmed)
    get registrations_path

    assert_response :success
    assert_includes response.body, "confirmed"
  end

  test "viewing registrations does not change the database" do
    sign_in @owner
    counts_before = [User.count, Club.count, ClubMembership.count, TournamentRegistration.count]

    get registrations_path

    assert_response :success
    assert_equal counts_before,
                 [User.count, Club.count, ClubMembership.count, TournamentRegistration.count]
  end

  test "sensitive query parameters do not change registration scope or records" do
    sign_in @owner
    counts_before = [User.count, Club.count, ClubMembership.count, TournamentRegistration.count]

    get registrations_path(
      club_id: @club.id,
      tournament_id: @tournament.id,
      user_id: @outsider.id,
      status: "confirmed",
      role: "owner"
    )

    assert_response :success
    assert_includes response.body, @player.name
    assert_equal counts_before,
                 [User.count, Club.count, ClubMembership.count, TournamentRegistration.count]
  end

  test "only GET is supported for the index resource" do
    sign_in @owner

    post registrations_path

    assert_response :not_found
  end

  private

  def registrations_path(club_id: @club.id, tournament_id: @tournament.id, **query_params)
    path = "/clubs/#{club_id}/tournaments/#{tournament_id}/registrations"
    query = Rack::Utils.build_query(query_params)

    query.empty? ? path : "#{path}?#{query}"
  end
end
