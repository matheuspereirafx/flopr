require "test_helper"

class SubscriptionChangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = Club.create!(name: "Subscription Change Club")
    @other_club = Club.create!(name: "Other Subscription Club")
    @owner = create_user("change_owner")
    @admin = create_user("change_admin")
    @dealer = create_user("change_dealer")
    @player = create_user("change_player")
    @outsider = create_user("change_outsider")

    create_membership(@owner, @club, :owner)
    create_membership(@admin, @club, :admin)
    create_membership(@dealer, @club, :dealer)
    create_membership(@player, @club, :player)
    create_membership(@outsider, @other_club, :owner)

    @current_plan = create_plan(
      name: "Profissional Anual",
      price: 1_000,
      billing_period: :yearly,
      tier: 2,
      features: %w[invitations guest_list buy_ins transactions prize_pool]
    )
    @future_plan = create_plan(
      name: "Iniciante Mensal",
      price: 100,
      billing_period: :monthly,
      tier: 1,
      features: %w[invitations guest_list]
    )
    @higher_plan = create_plan(
      name: "Enterprise Mensal",
      price: 200,
      billing_period: :monthly,
      tier: 3,
      features: %w[invitations guest_list buy_ins transactions prize_pool recharges]
    )
    @inactive_plan = create_plan(
      name: "Inativo Mensal",
      price: 50,
      billing_period: :monthly,
      tier: 0,
      active: false,
      features: []
    )
    @subscription = ClubSubscription.create!(
      club: @club,
      plan: @current_plan,
      owner: @owner,
      status: :active,
      billing_period: :yearly,
      expires_at: 1.month.from_now
    )
  end

  test "redirects an unauthenticated user to login" do
    get new_club_subscription_change_path(@club)

    assert_redirected_to new_user_session_path
  end

  test "owner can view the downgrade page" do
    sign_in @owner

    get new_club_subscription_change_path(@club)

    assert_response :success
    assert_select "body", text: /#{@current_plan.name}/
    assert_select "body", text: /#{@future_plan.name}/
  end

  test "admin can view and request a downgrade" do
    sign_in @admin

    get new_club_subscription_change_path(@club)
    assert_response :success

    assert_difference("SubscriptionChange.count", 1) do
      post club_subscription_change_path(@club), params: valid_params
    end

    assert_redirected_to club_subscriptions_path
  end

  %i[dealer player].each do |role|
    test "#{role} cannot view or create a downgrade" do
      sign_in instance_variable_get("@#{role}")

      get new_club_subscription_change_path(@club)
      assert_response :forbidden

      assert_no_difference("SubscriptionChange.count") do
        post club_subscription_change_path(@club), params: valid_params
      end
      assert_response :forbidden
    end
  end

  test "a user without membership cannot create a downgrade" do
    sign_in @outsider

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@club), params: valid_params
    end

    assert_response :not_found
  end

  test "changing the club id cannot schedule a downgrade for another club" do
    sign_in @owner

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@other_club), params: valid_params
    end

    assert_response :not_found
  end

  test "creates a pending downgrade without changing the active subscription" do
    sign_in @owner

    assert_difference("SubscriptionChange.count", 1) do
      post club_subscription_change_path(@club), params: valid_params
    end

    change = SubscriptionChange.order(:created_at).last
    assert_predicate change, :pending?
    assert_equal @subscription.expires_at.to_i, change.effective_at.to_i
    assert_predicate @subscription.reload, :active?
    assert_equal @current_plan, @subscription.plan
  end

  test "ignores forged effective date, status, current plan, requester, and price" do
    sign_in @owner
    forged_date = 10.years.from_now

    post club_subscription_change_path(@club), params: valid_params.merge(
      effective_at: forged_date,
      status: "applied",
      current_plan_id: @higher_plan.id,
      requested_by_id: @outsider.id,
      price: 0
    )

    change = SubscriptionChange.order(:created_at).last
    assert_equal @subscription.expires_at.to_i, change.effective_at.to_i
    assert_predicate change, :pending?
    assert_equal @owner, change.requested_by
    assert_equal @current_plan, change.current_plan
  end

  test "rejects an equal plan" do
    sign_in @owner

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@club), params: change_params(new_plan_id: @current_plan.id)
    end

    assert_response :unprocessable_entity
  end

  test "rejects a higher plan" do
    sign_in @owner

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@club), params: change_params(new_plan_id: @higher_plan.id)
    end

    assert_response :unprocessable_entity
  end

  test "rejects an inactive plan" do
    sign_in @owner

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@club), params: change_params(new_plan_id: @inactive_plan.id)
    end

    assert_response :unprocessable_entity
  end

  test "rejects a second pending downgrade" do
    sign_in @owner
    post club_subscription_change_path(@club), params: valid_params

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@club), params: valid_params
    end

    assert_response :unprocessable_entity
  end

  test "rejects a subscription without an expiration date" do
    @subscription.update!(expires_at: nil)
    sign_in @owner

    assert_no_difference("SubscriptionChange.count") do
      post club_subscription_change_path(@club), params: valid_params
    end

    assert_response :unprocessable_entity
  end

  test "owner can cancel a pending downgrade without changing the active subscription" do
    sign_in @owner
    post club_subscription_change_path(@club), params: valid_params
    change = SubscriptionChange.order(:created_at).last

    assert_difference("SubscriptionChange.pending.count", -1) do
      delete club_subscription_change_path(@club)
    end

    assert_redirected_to club_subscriptions_path
    assert_predicate change.reload, :canceled?
    assert_predicate @subscription.reload, :active?
    assert_equal @current_plan, @subscription.plan
  end

  test "does not allow canceling a downgrade from another club" do
    sign_in @owner

    assert_no_difference("SubscriptionChange.count") do
      delete club_subscription_change_path(@other_club)
    end

    assert_response :not_found
  end

  private

  def valid_params
    change_params(new_plan_id: @future_plan.id)
  end

  def change_params(new_plan_id:)
    { subscription_change: { new_plan_id: new_plan_id } }
  end

  def create_plan(attributes)
    Plan.create!(
      name: attributes.fetch(:name),
      description: "Plano de teste",
      price: attributes.fetch(:price),
      billing_period: attributes.fetch(:billing_period),
      active: attributes.fetch(:active, true),
      tier: attributes.fetch(:tier),
      features: attributes.fetch(:features, [])
    )
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_user(username)
    User.create!(
      email: "#{username}@example.com",
      password: "password123",
      name: username,
      username: username
    )
  end
end
