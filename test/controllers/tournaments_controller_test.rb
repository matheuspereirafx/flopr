require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @other_club = Club.create!(name: "Other Poker House")

    @owner = create_user("owner@example.com")
    @admin = create_user("admin@example.com")
    @dealer = create_user("dealer@example.com")
    @player = create_user("player@example.com")
    @outsider = create_user("outsider@example.com")

    create_membership(@owner, @club, :owner)
    create_membership(@admin, @club, :admin)
    create_membership(@dealer, @club, :dealer)
    create_membership(@player, @club, :player)
    create_membership(@outsider, @other_club, :owner)
  end

  test "unauthenticated user cannot access new tournament form" do
    get new_club_tournament_path(@club)

    assert_redirected_to new_user_session_path
  end

  test "owner can access new tournament form" do
    sign_in @owner

    get new_club_tournament_path(@club)

    assert_response :success
  end

  test "admin can access new tournament form" do
    sign_in @admin

    get new_club_tournament_path(@club)

    assert_response :success
  end

  test "dealer cannot access new tournament form" do
    sign_in @dealer

    get new_club_tournament_path(@club)

    assert_response :forbidden
  end

  test "player cannot access new tournament form" do
    sign_in @player

    get new_club_tournament_path(@club)

    assert_response :forbidden
  end

  test "unauthenticated user cannot create tournament" do
    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club), params: tournament_payload
    end

    assert_redirected_to new_user_session_path
  end

  test "owner creates tournament with valid params" do
    sign_in @owner

    assert_difference "Tournament.count", 1 do
      post club_tournaments_path(@club), params: tournament_payload
    end

    tournament = Tournament.order(:created_at).last

    assert_redirected_to club_path(@club)
    assert_equal "Torneio criado com sucesso.", flash[:notice]
    assert_equal @club, tournament.club
    assert_equal "Friday Poker Night", tournament.name
    assert_equal "Rua das Flores, 123", tournament.location
    assert_equal 24, tournament.max_players
    assert_equal "posted", tournament.status
  end

  test "admin creates tournament with valid params" do
    sign_in @admin

    assert_difference "Tournament.count", 1 do
      post club_tournaments_path(@club), params: tournament_payload
    end

    assert_redirected_to club_path(@club)
    assert_equal @club, Tournament.order(:created_at).last.club
  end

  test "dealer cannot create tournament" do
    sign_in @dealer

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club), params: tournament_payload
    end

    assert_response :forbidden
  end

  test "player cannot create tournament" do
    sign_in @player

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club), params: tournament_payload
    end

    assert_response :forbidden
  end

  test "user without membership cannot access new tournament form" do
    sign_in @outsider

    get new_club_tournament_path(@club)

    assert_response :not_found
  end

  test "user without membership cannot create tournament" do
    sign_in @outsider

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club), params: tournament_payload
    end

    assert_response :not_found
  end

  test "owner of another club cannot create tournament in current club" do
    sign_in @outsider

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club), params: tournament_payload
    end

    assert_response :not_found
  end

  test "invalid params do not create tournament" do
    sign_in @owner

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club), params: tournament_payload(name: "")
    end

    assert_response :unprocessable_entity
  end

  test "missing name does not create tournament" do
    assert_missing_required_attribute(:name)
  end

  test "missing location does not create tournament" do
    assert_missing_required_attribute(:location)
  end

  test "missing max players does not create tournament" do
    assert_missing_required_attribute(:max_players)
  end

  test "missing starts at does not create tournament" do
    assert_missing_required_attribute(:starts_at)
  end

  test "club id param is ignored and tournament belongs to club from URL" do
    sign_in @owner

    assert_difference "Tournament.count", 1 do
      post club_tournaments_path(@club),
           params: tournament_payload(club_id: @other_club.id)
    end

    tournament = Tournament.order(:created_at).last

    assert_equal @club, tournament.club
    assert_not_equal @other_club, tournament.club
  end

  test "status param is ignored and tournament starts as posted" do
    sign_in @owner

    assert_difference "Tournament.count", 1 do
      post club_tournaments_path(@club),
           params: tournament_payload(status: "posted")
    end

    assert_equal "posted", Tournament.order(:created_at).last.status
  end

  test "sensitive user id param is ignored" do
    sign_in @owner

    assert_difference "Tournament.count", 1 do
      post club_tournaments_path(@club),
           params: tournament_payload(user_id: @outsider.id)
    end

    tournament = Tournament.order(:created_at).last

    assert_not tournament.respond_to?(:user_id)
  end

  test "unauthenticated user cannot access tournaments index" do
    get club_tournaments_path(@club)

    assert_redirected_to new_user_session_path
  end

  test "owner can access tournaments index" do
    sign_in @owner

    get club_tournaments_path(@club)

    assert_response :success
  end

  test "admin can access tournaments index" do
    sign_in @admin

    get club_tournaments_path(@club)

    assert_response :success
  end

  test "dealer can access tournaments index" do
    sign_in @dealer

    get club_tournaments_path(@club)

    assert_response :success
  end

  test "player can access tournaments index" do
    sign_in @player

    get club_tournaments_path(@club)

    assert_response :success
  end

  test "user without membership cannot access tournaments index" do
    sign_in @outsider

    get club_tournaments_path(@club)

    assert_response :not_found
  end

  test "tournaments index lists only tournaments from current club" do
    current_tournament = create_tournament(
      @club,
      name: "Current Club Tournament",
      location: "Mesa Principal"
    )
    other_tournament = create_tournament(
      @other_club,
      name: "Other Club Tournament",
      location: "Sala Reservada"
    )

    sign_in @owner
    get club_tournaments_path(@club)

    assert_response :success
    assert_includes response.body, current_tournament.name
    assert_includes response.body, current_tournament.location
    assert_includes response.body, current_tournament.max_players.to_s
    assert_includes response.body, current_tournament.status.humanize
    assert_not_includes response.body, other_tournament.name
    assert_not_includes response.body, other_tournament.location
  end

  test "tournaments index presents basic tournament information" do
    tournament = create_tournament(
      @club,
      name: "Saturday Deep Stack",
      location: "Rua Central, 88",
      max_players: 32,
      status: :posted
    )

    sign_in @player
    get club_tournaments_path(@club)

    assert_response :success
    assert_includes response.body, tournament.name
    assert_includes response.body, tournament.location
    assert_includes response.body, "32"
    assert_includes response.body, "Posted"
    assert_includes response.body, "Buy-in"
    assert_includes response.body, "R$ 250"
  end

  test "tournaments index respects role actions for dealer and player" do
    create_tournament(@club)

    [@dealer, @player].each do |user|
      sign_in user
      get club_tournaments_path(@club)

      assert_response :success
      assert_not_includes response.body, new_club_tournament_path(@club)
      sign_out user
    end
  end

  test "tournaments index shows management menu only to owner and admin" do
    tournament = create_tournament(@club)

    sign_in @owner
    get club_tournaments_path(@club)

    assert_includes response.body, edit_club_tournament_path(@club, tournament)
    assert_includes response.body, club_tournament_path(@club, tournament)
    sign_out @owner

    sign_in @admin
    get club_tournaments_path(@club)

    assert_includes response.body, edit_club_tournament_path(@club, tournament)
    assert_not_includes response.body, "Excluir torneio"
    sign_out @admin

    sign_in @dealer
    get club_tournaments_path(@club)

    assert_not_includes response.body, edit_club_tournament_path(@club, tournament)
  end

  test "tournaments index shows empty state when club has no tournaments" do
    empty_club = Club.create!(name: "Empty Club")
    create_membership(@owner, empty_club, :owner)

    sign_in @owner
    get club_tournaments_path(empty_club)

    assert_response :success
    assert_includes response.body, "Nenhum torneio criado ainda."
  end

  test "owner can access tournament edit form" do
    tournament = create_tournament(@club)
    sign_in @owner

    get edit_club_tournament_path(@club, tournament)

    assert_response :success
  end

  test "admin can access tournament edit form" do
    tournament = create_tournament(@club)
    sign_in @admin

    get edit_club_tournament_path(@club, tournament)

    assert_response :success
  end

  test "dealer and player cannot access tournament edit form" do
    tournament = create_tournament(@club)

    [@dealer, @player].each do |user|
      sign_in user
      get edit_club_tournament_path(@club, tournament)

      assert_response :forbidden
      sign_out user
    end
  end

  test "user cannot edit tournament from another club" do
    tournament = create_tournament(@other_club)
    sign_in @owner

    get edit_club_tournament_path(@club, tournament)

    assert_response :not_found
  end

  test "owner updates tournament with permitted params" do
    tournament = create_tournament(@club)
    sign_in @owner

    patch club_tournament_path(@club, tournament), params: tournament_payload(
      name: "Sunday High Roller",
      max_players: 48
    )

    assert_redirected_to club_path(@club)
    assert_equal "Torneio atualizado com sucesso.", flash[:notice]
    assert_equal "Sunday High Roller", tournament.reload.name
    assert_equal 48, tournament.max_players
  end

  test "admin updates tournament but cannot change status" do
    tournament = create_tournament(@club, status: :posted)
    sign_in @admin

    patch club_tournament_path(@club, tournament), params: tournament_payload(
      name: "Admin Update",
      status: "finished"
    )

    assert_redirected_to club_path(@club)
    assert_equal "Admin Update", tournament.reload.name
    assert_equal "posted", tournament.status
  end

  test "dealer and player cannot update tournament" do
    tournament = create_tournament(@club)

    [@dealer, @player].each do |user|
      sign_in user
      patch club_tournament_path(@club, tournament),
            params: tournament_payload(name: "Unauthorized update")

      assert_response :forbidden
      assert_equal "Friday Poker Night", tournament.reload.name
      sign_out user
    end
  end

  test "only owner can delete tournament" do
    tournament = create_tournament(@club)
    sign_in @admin

    assert_no_difference "Tournament.count" do
      delete club_tournament_path(@club, tournament)
    end

    assert_response :forbidden
    sign_out @admin

    sign_in @owner
    assert_difference "Tournament.count", -1 do
      delete club_tournament_path(@club, tournament)
    end

    assert_redirected_to club_path(@club)
    assert_equal "Torneio excluído com sucesso.", flash[:notice]
  end

  private

  def create_user(email)
    User.create!(
      email: email,
      password: "password123",
      name: email.split("@").first
    )
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_tournament(club, attributes = {})
    defaults = {
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :posted
    }

    club.tournaments.create!(defaults.merge(attributes))
  end

  def tournament_payload(overrides = {})
    {
      tournament: valid_tournament_attributes.merge(overrides)
    }
  end

  def valid_tournament_attributes
    {
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now
    }
  end

  def assert_missing_required_attribute(attribute)
    sign_in @owner

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club),
           params: tournament_payload(attribute => nil)
    end

    assert_response :unprocessable_entity
  end
end
