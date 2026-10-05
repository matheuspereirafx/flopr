require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Plan.create!(
      name: "Free",
      description: "Plano gratuito",
      price: 0,
      billing_period: :monthly,
      active: true
    )
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

  test "owner can create a second club" do
    sign_in @owner

    assert_difference("Club.count", 1) do
      assert_difference("ClubMembership.count", 1) do
        post clubs_path, params: { club: { name: "Second Club" } }
      end
    end

    assert_redirected_to clubs_path
    assert_equal :owner, Club.find_by!(name: "Second Club").club_memberships.find_by!(user: @owner).role.to_sym
  end

  test "creates a free active subscription for a new club" do
    sign_in @owner

    assert_difference ["Club.count", "ClubMembership.count", "ClubSubscription.count"], 1 do
      post clubs_path, params: { club: { name: "Free Club" } }
    end

    club = Club.find_by!(name: "Free Club")
    subscription = club.active_club_subscription

    assert_redirected_to clubs_path
    assert_equal "Free", subscription.plan.name
    assert_equal @owner, subscription.owner
    assert_predicate subscription, :active?
    assert_equal "monthly", subscription.billing_period
  end

  test "redirects a new club to the selected plan after creation" do
    user = User.create!(
      email: "new-club-owner@example.com",
      password: "password123",
      name: "New Club Owner",
      username: "new_club_owner"
    )
    plan = Plan.create!(
      name: "Profissional",
      description: "Para clubes avançados",
      price: 119,
      billing_period: "monthly",
      active: true
    )
    sign_in user

    get new_club_path(plan_id: plan.id)

    assert_response :success
    assert_select "input[type='hidden'][name='plan_id'][value='#{plan.id}']", count: 1

    post clubs_path, params: { club: { name: "New Club" }, plan_id: plan.id }

    assert_redirected_to new_club_subscription_path(plan_id: plan.id)
    assert_equal "New Club", user.reload.owned_clubs.first.name
  end

  test "owner cannot create a third club" do
    second_club = Club.create!(name: "Second Club")
    ClubMembership.create!(user: @owner, club: second_club, role: :owner)
    sign_in @owner

    assert_no_difference(["Club.count", "ClubMembership.count"]) do
      post clubs_path, params: { club: { name: "Third Club" } }
    end

    assert_redirected_to clubs_path
    assert_equal "Você já possui o limite de 2 clubes.", flash[:alert]
    assert_nil Club.find_by(name: "Third Club")
  end

  test "does not show the create club button after reaching the owner limit" do
    second_club = Club.create!(name: "Second Club")
    ClubMembership.create!(user: @owner, club: second_club, role: :owner)
    sign_in @owner

    get clubs_path

    assert_response :success
    assert_select ".clubs-header a[href='#{new_club_path}']", count: 0
    assert_select ".clubs-header__limit-message", text: /limite de 2 clubes/
  end

  test "does not allow access to the new club form after reaching the owner limit" do
    second_club = Club.create!(name: "Second Club")
    ClubMembership.create!(user: @owner, club: second_club, role: :owner)
    sign_in @owner

    get new_club_path

    assert_redirected_to clubs_path
    assert_equal "Você já possui o limite de 2 clubes.", flash[:alert]
  end

  test "does not expose a club deletion route" do
    delete club_path(@club)

    assert_response :not_found
  end

  test "does not show the club deletion action" do
    sign_in @owner
    get clubs_path

    assert_response :success
    assert_select ".inside-menu-item--danger", count: 0
    assert_select "form[action='#{club_path(@club)}'][method='post'] input[name='_method'][value='delete']", count: 0
  end

  test "lists only clubs where the user is an owner or admin" do
    admin_club = Club.create!(name: "Admin Club")
    dealer_club = Club.create!(name: "Dealer Club")
    player_club = Club.create!(name: "Player Club")

    ClubMembership.create!(user: @owner, club: admin_club, role: :admin)
    ClubMembership.create!(user: @owner, club: dealer_club, role: :dealer)
    ClubMembership.create!(user: @owner, club: player_club, role: :player)

    sign_in @owner
    get clubs_path

    assert_response :success
    assert_select ".club-card h3", text: "Poker House", count: 1
    assert_select ".club-card h3", text: "Admin Club", count: 1
    assert_select ".club-card h3", text: "Dealer Club", count: 0
    assert_select ".club-card h3", text: "Player Club", count: 0
  end

  test "does not return dealer or player clubs when filtering the index" do
    dealer_club = Club.create!(name: "Dealer Poker Club")
    player_club = Club.create!(name: "Player Poker Club")

    ClubMembership.create!(user: @owner, club: dealer_club, role: :dealer)
    ClubMembership.create!(user: @owner, club: player_club, role: :player)

    sign_in @owner
    get clubs_path, params: { query: "Poker" }

    assert_response :success
    assert_select ".club-card", count: 1
    assert_select ".club-card h3", text: "Poker House", count: 1
    assert_select ".club-card h3", text: "Dealer Poker Club", count: 0
    assert_select ".club-card h3", text: "Player Poker Club", count: 0
  end

  test "owner can configure the club PIX payment settings" do
    sign_in @owner

    patch club_path(@club), params: {
      club: {
        pix_key: "owner@example.com",
        pix_key_type: "email",
        pix_recipient_name: "Poker House"
      }
    }

    assert_redirected_to clubs_path
    assert_equal "owner@example.com", @club.reload.pix_key
    assert_equal "email", @club.pix_key_type
  end

  test "player cannot configure the club PIX payment settings" do
    sign_in @player

    patch club_path(@club), params: { club: { pix_key: "player@example.com" } }

    assert_response :not_found
    assert_nil @club.reload.pix_key
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

  test "free plan shows a modal instead of a create link after the monthly limit" do
    free_plan = Plan.find_by!(name: "Free")
    ClubSubscription.create!(
      club: @club,
      plan: free_plan,
      owner: @owner,
      status: :active,
      billing_period: free_plan.billing_period
    )
    create_tournament

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select "a.club-show__create-tournament[href='#{new_club_tournament_path(@club)}']", count: 0
    assert_select "button.club-show__create-tournament[data-action='plan-limit-modal#open']", count: 1
    assert_select ".plan-limit-modal", count: 1
    assert_includes response.body, "O plano Free permite criar 1 torneio por mês."
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

  test "shows only the tournament status when its clock is finished" do
    tournament = create_tournament(name: "Finished clock")
    tournament.charge_options.create!(kind: :buy_in, active: true, amount: 50, chip_amount: 10_000)
    tournament.update!(status: :posted)
    TournamentClockState.create_initial_for!(tournament).update!(status: :finished)

    sign_in @owner
    get club_path(@club)

    assert_select ".tournament-card[data-clock-status='finished']", count: 1 do
      assert_select ".tournament-card__status--posted", text: /Publicado/, count: 1
      assert_select ".tournament-card__status--clock", count: 0
    end
  end

  private

  def create_tournament(attributes = {})
    tournament = @club.tournaments.build(
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      google_place_id: "ChIJtestplace",
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
