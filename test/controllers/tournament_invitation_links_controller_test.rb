require "test_helper"

class TournamentInvitationLinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @owner = create_user("owner@example.com")
    @admin = create_user("admin@example.com")
    @dealer = create_user("dealer@example.com")
    @candidate = create_user("candidate@example.com")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    ClubMembership.create!(user: @admin, club: @club, role: :admin)
    ClubMembership.create!(user: @dealer, club: @club, role: :dealer)
    @tournament = create_tournament(@club)
  end

  test "owner and admin can view the direct tournament show invite URL" do
    [@owner, @admin].each do |user|
      sign_in user

      get club_tournament_invite_link_path(@club, @tournament)

      assert_response :success
      assert_select "input[value=?]", club_tournament_url(@club, @tournament, invite_token: @tournament.invite_token)
      sign_out user
    end
  end

  test "a user outside the club sees the tournament show with the invitation modal" do
    sign_in @candidate

    get club_tournament_path(@club, @tournament, invite_token: @tournament.invite_token)

    assert_response :success
    assert_select ".tournament-show-shell"
    assert_select ".tournament-invitation-overlay h2", "Convite para torneio"
    assert_select "button", "Confirmar presença"
  end

  test "confirming from the invite modal creates membership and confirmed registration" do
    sign_in @candidate

    assert_difference ["TournamentRegistration.count", "ClubMembership.count"], 1 do
      patch confirm_tournament_invitation_path(@tournament.invite_token)
    end

    registration = TournamentRegistration.find_by!(tournament: @tournament, user: @candidate)
    assert_predicate registration, :confirmed?
    assert_equal "player", @candidate.club_memberships.find_by!(club: @club).role
    assert_redirected_to club_tournament_path(@club, @tournament)
  end

  test "confirming preserves an existing club role" do
    sign_in @dealer

    assert_difference "TournamentRegistration.count", 1 do
      assert_no_difference "ClubMembership.count" do
        patch confirm_tournament_invitation_path(@tournament.invite_token)
      end
    end

    assert_predicate TournamentRegistration.find_by!(tournament: @tournament, user: @dealer), :confirmed?
    assert_predicate @dealer.club_memberships.find_by!(club: @club), :dealer?
  end

  test "a token cannot be used to open another tournament show" do
    another_tournament = create_tournament(@club, name: "Saturday Poker Night")
    sign_in @candidate

    get club_tournament_path(@club, another_tournament, invite_token: @tournament.invite_token)

    assert_response :not_found
  end

  test "finished tournaments and invalid tokens are not accessible through the invite route" do
    sign_in @candidate
    @tournament.update!(status: :finished)

    get club_tournament_path(@club, @tournament, invite_token: @tournament.invite_token)
    assert_response :not_found

    get club_tournament_path(@club, @tournament, invite_token: "invalid")
    assert_response :not_found
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", name: email.split("@").first)
  end

  def create_tournament(club, name: "Friday Poker Night")
    tournament = club.tournaments.build(
      name: name,
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft
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
