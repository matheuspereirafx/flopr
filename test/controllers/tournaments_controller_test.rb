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

  test "only owner can access new tournament form" do
    sign_in @owner
    get new_club_tournament_path(@club)
    assert_response :success

    [@admin, @dealer, @player].each do |user|
      sign_out @owner
      sign_in user
      get new_club_tournament_path(@club)
      assert_response :forbidden
    end
  end

  test "unauthenticated user is redirected and outsider receives not found" do
    get new_club_tournament_path(@club)
    assert_redirected_to new_user_session_path

    sign_in @outsider
    get new_club_tournament_path(@club)
    assert_response :not_found
  end

  test "every club member can view a tournament overview" do
    tournament = create_tournament(@club)

    [@owner, @admin, @dealer, @player].each do |user|
      sign_in user

      get club_tournament_path(@club, tournament)

      assert_response :success
      assert_select "h1", tournament.name
      assert_select ".overview-prize-pool__hint", "Premiação disponível após a finalização do torneio."
      sign_out user
    end
  end

  test "overview participation displays registration statuses and available slots" do
    tournament = create_tournament(@club, max_players: 3)
    TournamentRegistration.create!(tournament: tournament, user: @dealer, status: :confirmed)
    TournamentRegistration.create!(tournament: tournament, user: @player, status: :pending)
    sign_in @owner

    get club_tournament_path(@club, tournament)

    assert_select "[data-participation-status='confirmed'] strong", "1"
    assert_select "[data-participation-status='pending'] strong", "1"
    assert_select "[data-participation-status='available-slots'] strong", "2"
  end

  test "only owner and admin see the button that copies the invite link" do
    tournament = create_tournament(@club)

    [@owner, @admin].each do |user|
      sign_in user
      get club_tournament_path(@club, tournament)

      assert_select "button[data-controller='copy-invite-link'][data-copy-invite-link-url-value=?]",
                    club_tournament_url(@club, tournament, invite_token: tournament.invite_token)
      assert_select "button[data-copied-message='Link copiado']", count: 1
      sign_out user
    end

    [@dealer, @player].each do |user|
      sign_in user
      get club_tournament_path(@club, tournament)

      assert_select "button[data-controller='copy-invite-link']", count: 0
      sign_out user
    end
  end

  test "a member cannot view a tournament from another club by changing its id" do
    tournament = create_tournament(@other_club)
    sign_in @owner

    get club_tournament_path(@club, tournament)

    assert_response :not_found
  end

  test "owner creates tournament with five blind levels" do
    sign_in @owner

    assert_difference "Tournament.count", 1 do
      post club_tournaments_path(@club), params: tournament_payload
    end

    tournament = Tournament.order(:created_at).last
    assert_equal [1, 2, 3, 4, 5], tournament.blind_levels.pluck(:level)
    assert_equal [15], tournament.blind_levels.reorder(nil).distinct.pluck(:duration_minutes)
    assert_redirected_to new_club_tournament_charge_options_path(@club, tournament)
    assert_equal "draft", tournament.status
  end

  test "creating a tournament also creates its initial clock state" do
    sign_in @owner

    assert_difference ["Tournament.count", "TournamentClockState.count"], 1 do
      post club_tournaments_path(@club), params: tournament_payload
    end

    tournament = Tournament.order(:created_at).last
    assert_equal tournament.blind_levels.first, tournament.clock_state.current_blind_level
    assert_equal tournament.blind_levels.first.duration_minutes * 60,
                 tournament.clock_state.remaining_seconds
    assert tournament.clock_state.not_started?
  end

  test "new tournament form presents continue as the primary action" do
    sign_in @owner

    get new_club_tournament_path(@club)

    assert_response :success
    assert_select "button[type='submit'][title='Continuar'][aria-label='Continuar']"
  end

  test "owner cannot create a tournament with a name already used in different casing" do
    create_tournament(@club)
    sign_in @owner

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club),
           params: tournament_payload(name: "FRIDAY POKER NIGHT")
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "já está em uso"
  end

  test "owner creates exactly ten blind levels when selected count is ten" do
    sign_in @owner

    post club_tournaments_path(@club),
         params: tournament_payload(
           blind_levels_count: 10,
           blind_levels_attributes: blind_levels_attributes(10)
         )

    tournament = Tournament.order(:created_at).last
    assert_equal 10, tournament.blind_levels.count
    assert_equal (1..10).to_a, tournament.blind_levels.pluck(:level)
  end

  test "non owners cannot create tournaments" do
    [@admin, @dealer, @player].each do |user|
      sign_in user

      assert_no_difference "Tournament.count" do
        post club_tournaments_path(@club), params: tournament_payload
      end

      assert_response :forbidden
      sign_out user
    end
  end

  test "creation below the minimum number of levels fails" do
    sign_in @owner

    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club),
           params: tournament_payload(
             blind_levels_count: 4,
             blind_levels_attributes: blind_levels_attributes(4)
           )
    end

    assert_response :unprocessable_entity
  end

  test "creation with divergent durations fails" do
    attributes = blind_levels_attributes
    attributes.last[:duration_minutes] = 30

    sign_in @owner
    assert_no_difference "Tournament.count" do
      post club_tournaments_path(@club),
           params: tournament_payload(blind_levels_attributes: attributes)
    end

    assert_response :unprocessable_entity
  end

  test "owner can edit and update tournament blind structure" do
    tournament = create_tournament(@club)
    original_level = tournament.blind_levels.first

    sign_in @owner
    get edit_club_tournament_path(@club, tournament)
    assert_response :success

    patch club_tournament_path(@club, tournament),
          params: tournament_payload(
            blind_levels_count: 6,
            blind_levels_attributes: tournament.blind_levels.map do |level|
              level.attributes.slice("id", "level", "duration_minutes", "small_blind", "big_blind", "ante")
            end + blind_levels_attributes(1, start_level: 6)
          )

    assert_redirected_to edit_club_tournament_charge_options_path(@club, tournament)
    assert_equal "draft", tournament.reload.status
    assert_equal 6, tournament.reload.blind_levels.count
    assert_equal original_level.small_blind, tournament.blind_levels.first.small_blind
  end

  test "edit form displays the tournament start date and time" do
    starts_at = Time.zone.local(2026, 8, 20, 19, 30)
    tournament = create_tournament(@club, starts_at: starts_at)

    sign_in @owner
    get edit_club_tournament_path(@club, tournament)

    assert_response :success
    assert_select "input[name='tournament[starts_at]'][type='datetime-local'][value='2026-08-20T19:30'][data-action='click->date-time-picker#open'].tournament-form__datetime-input"
    assert_select ".input-icon img.input-icon__image", count: 3
    assert_select "img[src*='Icondate']", count: 1
    assert_select "img[src*='Iconlocation']", count: 1
    assert_select "img[src*='Iconplayer']", count: 1
  end

  test "owner can remove final blind levels while keeping the minimum" do
    tournament = create_tournament(
      @club,
      blind_levels_count: 6,
      blind_levels_attributes: blind_levels_attributes(6)
    )
    levels = tournament.blind_levels.to_a

    sign_in @owner
    patch club_tournament_path(@club, tournament),
          params: tournament_payload(
            blind_levels_count: 5,
            blind_levels_attributes: levels.map do |level|
              attributes = level.attributes.slice("id", "level", "duration_minutes", "small_blind", "big_blind", "ante")
              attributes[:_destroy] = "1" if level == levels.last
              attributes
            end
          )

    assert_redirected_to edit_club_tournament_charge_options_path(@club, tournament)
    assert_equal [1, 2, 3, 4, 5], tournament.reload.blind_levels.pluck(:level)
  end

  test "update below the minimum number of levels fails" do
    tournament = create_tournament(@club)
    levels = tournament.blind_levels.to_a

    sign_in @owner
    patch club_tournament_path(@club, tournament),
          params: tournament_payload(
            blind_levels_count: 4,
            blind_levels_attributes: levels.map do |level|
              attributes = level.attributes.slice("id", "level", "duration_minutes", "small_blind", "big_blind", "ante")
              attributes[:_destroy] = "1" if level == levels.last
              attributes
            end
          )

    assert_response :unprocessable_entity
    assert_equal 5, tournament.reload.blind_levels.count
  end

  test "non owners cannot edit update or delete a tournament" do
    tournament = create_tournament(@club)

    [@admin, @dealer, @player].each do |user|
      sign_in user

      get edit_club_tournament_path(@club, tournament)
      assert_response :forbidden

      patch club_tournament_path(@club, tournament), params: tournament_payload(name: "Unauthorized")
      assert_response :forbidden
      assert_equal "Friday Poker Night", tournament.reload.name

      assert_no_difference "Tournament.count" do
        delete club_tournament_path(@club, tournament)
      end
      assert_response :forbidden

      sign_out user
    end
  end

  test "owner can delete tournament" do
    tournament = create_tournament(@club)
    sign_in @owner

    assert_difference "Tournament.count", -1 do
      delete club_tournament_path(@club, tournament)
    end

    assert_redirected_to club_path(@club)
  end

  test "owner can delete a tournament with charge options linked to blind levels" do
    tournament = create_tournament(@club)
    TournamentChargeOption.create!(
      tournament: tournament,
      kind: :buy_in,
      active: true,
      amount: 50,
      chip_amount: 10_000
    )
    TournamentChargeOption.create!(
      tournament: tournament,
      kind: :rebuy,
      active: true,
      amount: 50,
      chip_amount: 10_000,
      available_from_level: tournament.blind_levels.first,
      available_until_level: tournament.blind_levels.third
    )
    sign_in @owner

    assert_difference "Tournament.count", -1 do
      assert_difference "TournamentChargeOption.count", -2 do
        assert_difference "BlindLevel.count", -5 do
          delete club_tournament_path(@club, tournament)
        end
      end
    end

    assert_redirected_to club_path(@club)
  end

  test "sensitive parameters are ignored" do
    sign_in @owner

    post club_tournaments_path(@club),
         params: tournament_payload(
           club_id: @other_club.id,
           status: "finished",
           user_id: @outsider.id
         )

    tournament = Tournament.order(:created_at).last
    assert_equal @club, tournament.club
    assert_equal "draft", tournament.status
    assert_not tournament.respond_to?(:user_id)
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", name: email.split("@").first)
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_tournament(club, attributes = {})
    club.tournaments.create!(valid_tournament_attributes.merge(attributes))
  end

  def tournament_payload(overrides = {})
    { tournament: valid_tournament_attributes.merge(overrides) }
  end

  def valid_tournament_attributes
    {
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft,
      blind_levels_count: 5,
      blind_levels_attributes: blind_levels_attributes
    }
  end

  def blind_levels_attributes(count = 5, start_level: 1)
    count.times.map do |index|
      level = start_level + index
      {
        level: level,
        duration_minutes: 15,
        small_blind: level * 100,
        big_blind: level * 200,
        ante: 0
      }
    end
  end
end
