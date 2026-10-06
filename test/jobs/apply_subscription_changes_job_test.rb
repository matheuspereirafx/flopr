require "test_helper"

class ApplySubscriptionChangesJobTest < ActiveJob::TestCase
  setup do
    @owner = create_user("job_owner")
    @club = Club.create!(name: "Subscription Job Club")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
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
    @effective_at = 1.day.ago
    @subscription = ClubSubscription.create!(
      club: @club,
      plan: @current_plan,
      owner: @owner,
      status: :active,
      billing_period: :yearly,
      expires_at: @effective_at
    )
  end

  test "applies an overdue pending downgrade in one transaction" do
    change = create_change

    assert_difference("ClubSubscription.count", 1) do
      ApplySubscriptionChangesJob.perform_now
    end

    assert_predicate @subscription.reload, :expired?
    new_subscription = @club.reload.active_club_subscription
    assert_equal @future_plan, new_subscription.plan
    assert_equal "monthly", new_subscription.billing_period
    assert_equal @future_plan.subscription_expires_at(@effective_at).to_i, new_subscription.expires_at.to_i
    assert_predicate change.reload, :applied?
    assert_not_nil change.applied_at
  end

  test "does not apply a pending downgrade before its effective date" do
    change = create_change(effective_at: 1.day.from_now)

    assert_no_difference("ClubSubscription.count") do
      ApplySubscriptionChangesJob.perform_now
    end

    assert_predicate change.reload, :pending?
    assert_predicate @subscription.reload, :active?
  end

  test "does not apply a canceled downgrade" do
    change = create_change(status: :canceled, canceled_at: Time.current)

    assert_no_difference("ClubSubscription.count") do
      ApplySubscriptionChangesJob.perform_now
    end

    assert_predicate change.reload, :canceled?
    assert_predicate @subscription.reload, :active?
  end

  test "is idempotent when the job runs more than once" do
    change = create_change

    ApplySubscriptionChangesJob.perform_now
    assert_no_difference("ClubSubscription.count") do
      ApplySubscriptionChangesJob.perform_now
    end

    assert_predicate change.reload, :applied?
    assert_equal 1, @club.club_subscriptions.active.count
  end

  private

  def create_change(attributes = {})
    SubscriptionChange.create!({
      club: @club,
      club_subscription: @subscription,
      current_plan: @current_plan,
      new_plan: @future_plan,
      requested_by: @owner,
      change_type: :downgrade,
      status: :pending,
      effective_at: @effective_at
    }.merge(attributes))
  end

  def create_plan(attributes)
    Plan.create!(
      name: attributes.fetch(:name),
      description: "Plano de teste",
      price: attributes.fetch(:price),
      billing_period: attributes.fetch(:billing_period),
      active: true,
      tier: attributes.fetch(:tier),
      features: attributes.fetch(:features, [])
    )
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
