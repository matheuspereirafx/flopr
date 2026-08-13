require "test_helper"

class TournamentClocksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = create_club(name: "Poker House")
    @other_club = create_club(name: "Other Poker House")
    @tournament = create_tournament(club: @club)
    @other_tournament = create_tournament(club: @other_club)

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
  end

  test "unauthenticated users are redirected from the clock" do
    get club_tournament_clock_path(@club, @tournament)

    assert_redirected_to new_user_session_path
  end

  test "every club role can view its tournament clock" do
    [@owner, @admin, @dealer, @player].each do |user|
      sign_in user

      get club_tournament_clock_path(@club, @tournament)

      assert_response :success
      sign_out user
    end
  end

  test "a user without club membership receives not found" do
    sign_in @outsider

    get club_tournament_clock_path(@club, @tournament)

    assert_response :not_found
  end

  test "changing the tournament id cannot expose a tournament from another club" do
    sign_in @owner

    get club_tournament_clock_path(@club, @other_tournament)

    assert_response :not_found
  end

  test "owner and admin can start a not started clock" do
    [@owner, @admin].each do |user|
      state = TournamentClockState.create_initial_for!(@tournament)
      sign_in user

      post start_club_tournament_clock_path(@club, @tournament)

      assert_redirected_to club_tournament_clock_path(@club, @tournament)
      assert state.reload.running?
      sign_out user
      state.destroy!
    end
  end

  test "dealer player and outsider cannot start the clock" do
    [@dealer, @player, @outsider].each do |user|
      state = TournamentClockState.create_initial_for!(@tournament)
      sign_in user

      assert_no_changes -> { state.reload.attributes } do
        post start_club_tournament_clock_path(@club, @tournament)
      end

      assert_response(user == @outsider ? :not_found : :forbidden)
      sign_out user
      state.destroy!
    end
  end

  test "owner admin and dealer can pause a running clock" do
    [@owner, @admin, @dealer].each do |user|
      state = TournamentClockState.create_initial_for!(@tournament)
      state.start!(at: Time.current)
      sign_in user

      patch pause_club_tournament_clock_path(@club, @tournament)

      assert_redirected_to club_tournament_clock_path(@club, @tournament)
      assert state.reload.paused?
      sign_out user
      state.destroy!
    end
  end

  test "player cannot pause and does not change the clock" do
    state = TournamentClockState.create_initial_for!(@tournament)
    state.start!(at: Time.current)
    sign_in @player

    assert_no_changes -> { state.reload.attributes } do
      patch pause_club_tournament_clock_path(@club, @tournament)
    end

    assert_response :forbidden
    assert state.running?
  end

  test "only owner and admin can resume a paused clock" do
    [@owner, @admin].each do |user|
      state = TournamentClockState.create_initial_for!(@tournament)
      state.update!(status: :paused, paused_at: Time.current)
      sign_in user

      patch resume_club_tournament_clock_path(@club, @tournament)

      assert_redirected_to club_tournament_clock_path(@club, @tournament)
      assert state.reload.running?
      sign_out user
      state.destroy!
    end
  end

  test "dealer and player cannot resume a paused clock" do
    [@dealer, @player].each do |user|
      state = TournamentClockState.create_initial_for!(@tournament)
      state.update!(status: :paused, paused_at: Time.current)
      sign_in user

      patch resume_club_tournament_clock_path(@club, @tournament)

      assert_response :forbidden
      assert state.reload.paused?
      sign_out user
      state.destroy!
    end
  end

  test "operation routes ignore tampered clock attributes" do
    state = TournamentClockState.create_initial_for!(@tournament)
    sign_in @owner

    post start_club_tournament_clock_path(@club, @tournament), params: {
      tournament_clock_state: {
        tournament_id: @other_tournament.id,
        current_blind_level_id: @other_tournament.blind_levels.first.id,
        remaining_seconds: 1,
        status: "finished"
      }
    }

    state.reload
    assert_equal @tournament, state.tournament
    assert_equal @tournament.blind_levels.first, state.current_blind_level
    assert state.running?
    assert_not state.finished?
  end

  test "unauthenticated users are redirected from the clock state" do
    get clock_state_path_for(@club, @tournament)

    assert_redirected_to new_user_session_path
  end

  test "every club role can read the synchronized clock state" do
    [@owner, @admin, @dealer, @player].each do |user|
      sign_in user

      get clock_state_path_for(@club, @tournament)

      assert_response :success
      assert_equal "application/json", response.media_type
      sign_out user
    end
  end

  test "state synchronization advances every expired level and returns the current state" do
    state = TournamentClockState.create_initial_for!(@tournament)
    state.update!(
      status: :running,
      remaining_seconds: 15.minutes.to_i,
      started_at: 46.minutes.ago
    )
    sign_in @owner

    assert_difference "TournamentClockEvent.count", 3 do
      get clock_state_path_for(@club, @tournament)
    end

    assert_response :success
    state.reload
    assert_equal @tournament.blind_levels.fourth, state.current_blind_level
    assert_equal state.current_blind_level.id, response.parsed_body.fetch("current_blind_level_id")
    assert_equal state.remaining_seconds, response.parsed_body.fetch("remaining_seconds")
    assert_equal 4, response.parsed_body.dig("current_level", "level")
    assert_equal 800, response.parsed_body.dig("current_level", "big_blind")
    assert_equal 5, response.parsed_body.dig("next_level", "level")
  end

  test "state synchronization does not persist a running clock before the level ends" do
    state = TournamentClockState.create_initial_for!(@tournament)
    state.update!(
      status: :running,
      remaining_seconds: 15.minutes.to_i,
      started_at: 2.minutes.ago
    )
    persisted_attributes = state.attributes
    sign_in @owner

    get clock_state_path_for(@club, @tournament)

    assert_response :success
    assert_equal persisted_attributes, state.reload.attributes
    assert_in_delta 780, response.parsed_body.fetch("remaining_seconds"), 2
  end

  test "a user without membership cannot synchronize the clock state" do
    state = TournamentClockState.create_initial_for!(@tournament)
    sign_in @outsider

    assert_no_changes -> { state.reload.attributes } do
      assert_no_difference "TournamentClockEvent.count" do
        get clock_state_path_for(@club, @tournament)
      end
    end

    assert_response :not_found
  end

  test "a clock state cannot be exposed by changing the tournament id to another club" do
    state = TournamentClockState.create_initial_for!(@tournament)
    sign_in @owner

    assert_no_changes -> { state.reload.attributes } do
      assert_no_difference "TournamentClockEvent.count" do
        get clock_state_path_for(@club, @other_tournament)
      end
    end

    assert_response :not_found
  end

  test "state synchronization ignores tampered clock and history attributes" do
    state = TournamentClockState.create_initial_for!(@tournament)
    sign_in @owner

    get clock_state_path_for(@club, @tournament), params: {
      current_blind_level_id: @other_tournament.blind_levels.last.id,
      remaining_seconds: 1,
      status: "finished",
      tournament_clock_event: {
        tournament_id: @other_tournament.id,
        from_blind_level_id: @other_tournament.blind_levels.first.id,
        to_blind_level_id: @other_tournament.blind_levels.last.id,
        occurred_at: 1.year.from_now
      }
    }

    assert_response :success
    state.reload
    assert_equal @tournament, state.tournament
    assert_equal @tournament.blind_levels.first, state.current_blind_level
    assert_equal 15.minutes.to_i, state.remaining_seconds
    assert state.not_started?
    assert_equal 0, TournamentClockEvent.count
  end

  private

  def clock_state_path_for(club, tournament)
    "/clubs/#{club.id}/tournaments/#{tournament.id}/clock/state"
  end
end
