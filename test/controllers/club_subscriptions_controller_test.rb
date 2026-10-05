require "test_helper"

class ClubSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = Club.create!(name: "Owner Club")
    @other_club = Club.create!(name: "Other Club")
    @owner = create_user("owner")
    @admin = create_user("admin")
    @dealer = create_user("dealer")
    @player = create_user("player")
    @outsider = create_user("outsider")

    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    ClubMembership.create!(user: @admin, club: @club, role: :admin)
    ClubMembership.create!(user: @dealer, club: @club, role: :dealer)
    ClubMembership.create!(user: @player, club: @club, role: :player)
    ClubMembership.create!(user: @outsider, club: @other_club, role: :owner)

    @second_club = Club.create!(name: "Second Owner Club")
    ClubMembership.create!(user: @owner, club: @second_club, role: :owner)

    @plan = Plan.create!(name: "Iniciante", description: "Plano inicial", price: 49, billing_period: "monthly", active: true)
    @inactive_plan = Plan.create!(name: "Inativo", description: "Plano indisponível", price: 99, billing_period: "monthly", active: false)
  end

  test "redirects an unauthenticated user to login while preserving the selected plan" do
    get new_club_subscription_path(plan_id: @plan.id)

    assert_redirected_to new_user_session_path(plan_id: @plan.id)
  end

  test "owner sees the selected plan and all owned clubs" do
    sign_in @owner
    get new_club_subscription_path(plan_id: @plan.id)

    assert_response :success
    assert_select "option[value='#{@club.id}']", count: 1
    assert_select "option[value='#{@second_club.id}']", count: 1
    assert_select "option[value='#{@other_club.id}']", count: 0
  end

  test "owner creates an active subscription for the selected club" do
    sign_in @owner

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: {
        plan_id: @plan.id,
        club_id: @club.id
      }
    end

    assert_redirected_to clubs_path
    subscription = ClubSubscription.order(:created_at).last
    assert_equal @club, subscription.club
    assert_equal @plan, subscription.plan
    assert_equal @owner, subscription.owner
    assert_predicate subscription, :active?
    assert_equal @plan.billing_period, subscription.billing_period
  end

  test "confirms a successful subscription" do
    sign_in @owner
    post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }

    follow_redirect!

    assert_select ".alert", text: /contrat/i
  end

  test "does not create a subscription for a club owned by another user" do
    sign_in @owner

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @other_club.id }
    end

    assert_response :not_found
  end

  %i[admin dealer player].each do |role|
    test "#{role} cannot contract a plan" do
      sign_in instance_variable_get("@#{role}")

      assert_no_difference("ClubSubscription.count") do
        post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
      end

      assert_response :forbidden
    end
  end

  test "an authenticated user without membership cannot contract a plan" do
    sign_in @outsider

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_response :not_found
  end

  test "rejects an inexistent plan" do
    sign_in @owner

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: { plan_id: -1, club_id: @club.id }
    end

    assert_response :not_found
  end

  test "rejects an inactive plan" do
    sign_in @owner

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: { plan_id: @inactive_plan.id, club_id: @club.id }
    end

    assert_response :unprocessable_entity
  end

  test "ignores a forged owner id and records the authenticated user" do
    sign_in @owner

    post club_subscriptions_path, params: {
      plan_id: @plan.id,
      club_id: @club.id,
      owner_id: @outsider.id
    }

    assert_equal @owner.id, ClubSubscription.order(:created_at).last.owner_id
  end

  test "ignores forged status and billing period values" do
    sign_in @owner

    post club_subscriptions_path, params: {
      plan_id: @plan.id,
      club_id: @club.id,
      status: "canceled",
      billing_period: "yearly"
    }

    subscription = ClubSubscription.order(:created_at).last
    assert_predicate subscription, :active?
    assert_equal @plan.billing_period, subscription.billing_period
  end

  test "replaces the current active subscription with the selected plan" do
    current_plan = Plan.create!(name: "Free", description: "Plano atual", price: 0, billing_period: "monthly", active: true)
    current_subscription = ClubSubscription.create!(
      club: @club,
      plan: current_plan,
      owner: @owner,
      status: :active,
      billing_period: current_plan.billing_period
    )
    sign_in @owner

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_redirected_to clubs_path
    assert_predicate current_subscription.reload, :canceled?
    assert_equal @plan, @club.reload.active_club_subscription.plan
    assert_predicate @club.active_club_subscription, :active?
  end

  test "allows a new subscription after the previous one was canceled" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :canceled, billing_period: @plan.billing_period)
    sign_in @owner

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_predicate ClubSubscription.order(:created_at).last, :active?
  end

  test "allows a new subscription after the previous one expired" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :expired, billing_period: @plan.billing_period)
    sign_in @owner

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_predicate ClubSubscription.order(:created_at).last, :active?
  end

  test "rejects missing sensitive and required parameters without changing the database" do
    sign_in @owner

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: {
        owner_id: @owner.id,
        status: "active"
      }
    end

    assert_response :unprocessable_entity
  end

  private

  def create_user(username)
    User.create!(
      email: "#{username}-subscription@example.com",
      password: "password123",
      name: username.capitalize,
      username: "#{username}_subscription"
    )
  end
end
