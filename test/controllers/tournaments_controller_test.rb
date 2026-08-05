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

  Tournament.statuses.each_key do |status|
    test "owner deletes a #{status} tournament" do
      tournament = create_tournament(status:)
      sign_in @owner

      assert_difference "Tournament.count", -1 do
        delete club_tournament_path(@club, tournament)
      end

      assert_redirected_to club_path(@club)
      assert_equal "Torneio excluído com sucesso.", flash[:notice]
    end
  end

  test "unauthenticated user cannot delete tournament" do
    tournament = create_tournament

    assert_no_difference "Tournament.count" do
      delete club_tournament_path(@club, tournament)
    end

    assert_redirected_to new_user_session_path
  end

  test "admin cannot delete tournament" do
    assert_role_cannot_delete_tournament(@admin)
  end

  test "dealer cannot delete tournament" do
    assert_role_cannot_delete_tournament(@dealer)
  end

  test "player cannot delete tournament" do
    assert_role_cannot_delete_tournament(@player)
  end

  test "user without membership cannot delete tournament" do
    tournament = create_tournament
    sign_in @outsider

    assert_no_difference "Tournament.count" do
      delete club_tournament_path(@club, tournament)
    end

    assert_response :not_found
  end

  test "owner cannot delete tournament from another club by changing the tournament id" do
    other_tournament = create_tournament(club: @other_club)
    sign_in @owner

    assert_no_difference "Tournament.count" do
      delete club_tournament_path(@club, other_tournament)
    end

    assert_response :not_found
    assert Tournament.exists?(other_tournament.id)
  end

  test "owner sees a delete button with confirmation for each tournament" do
    tournament = create_tournament
    sign_in @owner

    get club_path(@club)

    assert_select "form[action='#{club_tournament_path(@club, tournament)}'][data-turbo-confirm='Tem certeza que deseja excluir este torneio?']" do
      assert_select "input[name='_method'][value='delete']"
    end
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

  def create_tournament(club: @club, status: :posted)
    Tournament.create!(
      **valid_tournament_attributes,
      club:,
      status:
    )
  end

  def assert_role_cannot_delete_tournament(user)
    tournament = create_tournament
    sign_in user

    assert_no_difference "Tournament.count" do
      delete club_tournament_path(@club, tournament)
    end

    assert_response :forbidden
    assert Tournament.exists?(tournament.id)
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
