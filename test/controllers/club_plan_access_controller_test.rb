require "test_helper"

class ClubPlanAccessControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = create_club("Plan Club")
    @other_club = create_club("Other Plan Club")
    @owner = create_user("owner-plan-access@example.com")
    @admin = create_user("admin-plan-access@example.com")
    @dealer = create_user("dealer-plan-access@example.com")
    @player = create_user("player-plan-access@example.com")
    @outsider = create_user("outsider-plan-access@example.com")

    create_membership(@owner, @club, :owner)
    create_membership(@admin, @club, :admin)
    create_membership(@dealer, @club, :dealer)
    create_membership(@player, @club, :player)
    create_membership(@outsider, @other_club, :owner)

    @free_plan = create_plan("Free", 0)
    @monthly_plan = create_plan("Plano R$ 190", 190)
    @premium_plan = create_plan("Plano R$ 290", 290)
    @tournament = create_tournament(@club, "Plan Access Tournament")
    @other_tournament = create_tournament(@other_club, "Other Plan Tournament")
    @buy_in = create_charge_option(@tournament, :buy_in, 100)
    @rebuy = create_charge_option(@tournament, :rebuy, 50)
  end

  test "unauthenticated users are redirected from plan-controlled resources" do
    get club_tournament_transactions_path(@club, @tournament)

    assert_redirected_to new_user_session_path
  end

  test "free plan allows tournament configuration and clock" do
    sign_in @owner

    get new_club_tournament_path(@club)
    assert_response :success

    subscribe(@club, @free_plan)
    post start_club_tournament_clock_path(@club, @tournament)
    assert_redirected_to club_tournament_clock_path(@club, @tournament)
    assert_predicate @tournament.reload.clock_state, :running?
  end

  test "a club without an active subscription cannot use paid features" do
    sign_in @owner

    get club_tournament_transactions_path(@club, @tournament)

    assert_response :forbidden
  end

  test "free plan blocks invitations for owner and admin" do
    subscribe(@club, @free_plan)

    [@owner, @admin].each do |user|
      sign_in user
      get club_tournament_invite_link_path(@club, @tournament)

      assert_response :forbidden
      sign_out user
    end
  end

  test "free plan blocks buy-in without creating a payment" do
    subscribe(@club, @free_plan)
    registration = TournamentRegistration.create!(
      tournament: @tournament,
      user: @player,
      status: :pending
    )
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post club_tournament_buy_in_payment_path(@club, @tournament)
    end

    assert_response :forbidden
    assert_predicate registration.reload, :pending?
  end

  test "free plan blocks transactions without changing their state" do
    subscribe(@club, @free_plan)
    payment = create_payment(@tournament, @player, @owner)
    sign_in @owner

    get club_tournament_transactions_path(@club, @tournament)
    assert_response :forbidden

    patch confirm_club_tournament_transaction_path(@club, @tournament, payment)
    assert_response :forbidden
    assert_predicate payment.reload, :pending?
  end

  test "free plan blocks recharge requests without creating a payment" do
    subscribe(@club, @free_plan)
    TournamentRegistration.create!(
      tournament: @tournament,
      user: @player,
      status: :confirmed
    )
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post club_tournament_recharges_path(@club, @tournament),
           params: { registration_payment: { tournament_charge_option_id: @rebuy.id } }
    end

    assert_response :forbidden
  end

  test "free plan blocks prize pool creation without changing the database" do
    subscribe(@club, @free_plan)
    sign_in @owner

    assert_no_difference "TournamentPrizePool.count" do
      post club_tournament_prize_pool_path(@club, @tournament),
           params: {
             prize_pool: {
               rake_percentage: 0,
               prize_positions_attributes: {
                 "0" => { position: 1, percentage: 100 }
               }
             }
           }
    end

    assert_response :forbidden
  end

  test "paid plans allow paid features while active" do
    [@monthly_plan, @premium_plan].each do |plan|
      subscribe(@club, plan)
      sign_in @owner

      get club_tournament_invite_link_path(@club, @tournament)
      assert_response :success

      get club_tournament_transactions_path(@club, @tournament)
      assert_response :success

      get new_club_tournament_prize_pool_path(@club, @tournament)
      assert_response :success

      sign_out @owner
      @club.reload.active_club_subscription.update!(status: :canceled)
    end
  end

  test "paid plan allows a player to create a buy-in payment" do
    subscribe(@club, @monthly_plan)
    registration = TournamentRegistration.create!(
      tournament: @tournament,
      user: @player,
      status: :pending
    )
    sign_in @player

    assert_difference "RegistrationPayment.count", 1 do
      post club_tournament_buy_in_payment_path(@club, @tournament)
    end

    assert_redirected_to club_tournament_path(@club, @tournament, payment: "buy_in")
    assert_predicate registration.reload.registration_payments.sole, :pending?
  end

  test "paid plan allows a confirmed player to request a recharge" do
    subscribe(@club, @monthly_plan)
    TournamentRegistration.create!(
      tournament: @tournament,
      user: @player,
      status: :confirmed
    )
    sign_in @player

    assert_difference "RegistrationPayment.count", 1 do
      post club_tournament_recharges_path(@club, @tournament),
           params: { registration_payment: { tournament_charge_option_id: @rebuy.id } }
    end

    assert_redirected_to club_tournament_recharges_path(@club, @tournament)
  end

  test "a canceled or expired subscription does not unlock paid features" do
    %i[canceled expired].each do |status|
      subscription = subscribe(@club, @monthly_plan)
      subscription.update!(status: status)
      sign_in @owner

      get club_tournament_transactions_path(@club, @tournament)

      assert_response :forbidden
      sign_out @owner
    end
  end

  test "a user without membership cannot use another club plan" do
    subscribe(@club, @monthly_plan)
    sign_in @outsider

    get club_tournament_transactions_path(@club, @tournament)

    assert_response :not_found
  end

  test "changing club and tournament ids cannot expose paid features from another club" do
    subscribe(@club, @monthly_plan)
    sign_in @owner

    get club_tournament_transactions_path(@other_club, @other_tournament)

    assert_response :not_found
  end

  test "starting a tournament counts against the free monthly limit" do
    subscribe(@club, @free_plan)
    first_tournament = @tournament
    second_tournament = create_tournament(@club, "Second Plan Access Tournament")
    sign_in @owner

    post start_club_tournament_clock_path(@club, first_tournament)
    assert_predicate first_tournament.reload.clock_state, :running?

    assert_no_changes -> { second_tournament.reload.clock_state.attributes } do
      post start_club_tournament_clock_path(@club, second_tournament)
    end

    assert_response :forbidden
    assert_predicate second_tournament.reload.clock_state, :not_started?
  end

  test "the paid monthly limits are four and nine started tournaments" do
    {
      @monthly_plan => 4,
      @premium_plan => 9
    }.each do |plan, limit|
      limit_club = create_club("#{plan.name} Limit Club")
      create_membership(@owner, limit_club, :owner)
      subscribe(limit_club, plan)
      sign_in @owner

      limit.times do |index|
        tournament = create_tournament(limit_club, "#{plan.name} Tournament #{index}")
        assert_equal plan, limit_club.reload.active_club_subscription.plan
        assert_equal index, limit_club.reload.started_tournaments_in_month.count
        post start_club_tournament_clock_path(limit_club, tournament)
        assert_response :redirect
        assert_predicate tournament.reload.clock_state, :running?
      end

      blocked_tournament = create_tournament(limit_club, "#{plan.name} Blocked Tournament")
      post start_club_tournament_clock_path(limit_club, blocked_tournament)

      assert_response :forbidden
      assert_predicate blocked_tournament.reload.clock_state, :not_started?
      sign_out @owner
      limit_club.reload.active_club_subscription.update!(status: :canceled)
    end
  end

  test "an active paid plan cannot be reduced before it expires" do
    subscribe(@club, @monthly_plan)
    sign_in @owner

    assert_no_difference "ClubSubscription.count" do
      post club_subscriptions_path,
           params: { plan_id: @free_plan.id, club_id: @club.id }
    end

    assert_response :unprocessable_entity
    assert_equal @monthly_plan, @club.reload.active_club_subscription.plan
  end

  private

  def create_club(name)
    Club.create!(name: name)
  end

  def create_user(email)
    User.create!(
      email: email,
      password: "password123",
      name: email.split("@").first,
      username: email.split("@").first.tr("-", "_")
    )
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_plan(name, price)
    Plan.create!(
      name: name,
      description: name,
      price: price,
      billing_period: :monthly,
      active: true
    )
  end

  def subscribe(club, plan)
    club.reload.active_club_subscription&.update!(status: :canceled)
    ClubSubscription.create!(
      club: club,
      plan: plan,
      owner: @owner,
      status: :active,
      billing_period: plan.billing_period
    )
  end

  def create_charge_option(tournament, kind, amount)
    TournamentChargeOption.create!(
      tournament: tournament,
      kind: kind,
      active: true,
      amount: amount,
      chip_amount: amount * 100
    )
  end

  def create_payment(tournament, user, recorded_by)
    registration = TournamentRegistration.create!(
      tournament: tournament,
      user: user,
      status: :pending
    )
    RegistrationPayment.create!(
      tournament_registration: registration,
      tournament_charge_option: @buy_in,
      amount: @buy_in.amount,
      status: :pending,
      provider: "manual",
      payment_method: :manual,
      recorded_by: recorded_by
    )
  end

  def create_tournament(club, name)
    tournament = club.tournaments.build(
      name: name,
      location: "Poker House",
      google_place_id: "ChIJtestplace-#{SecureRandom.hex(4)}",
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
    TournamentClockState.create_initial_for!(tournament)
    tournament
  end
end
