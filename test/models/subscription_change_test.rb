require "test_helper"

class SubscriptionChangeTest < ActiveSupport::TestCase
  setup do
    @owner = create_user("change_owner")
    @club = Club.create!(name: "Subscription Change Club")
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
    @subscription = ClubSubscription.create!(
      club: @club,
      plan: @current_plan,
      owner: @owner,
      status: :active,
      billing_period: :yearly,
      expires_at: 1.month.from_now
    )
  end

  test "belongs to the club subscription, both plans, requester, and club" do
    change = build_change

    assert_equal @subscription, change.club_subscription
    assert_equal @current_plan, change.current_plan
    assert_equal @future_plan, change.new_plan
    assert_equal @owner, change.requested_by
    assert_equal @club, change.club
  end

  test "supports downgrade change type and pending, applied, and canceled statuses" do
    assert_equal %w[downgrade], SubscriptionChange.change_types.keys
    assert_equal %w[pending applied canceled], SubscriptionChange.statuses.keys
  end

  test "is valid with a future effective date and a lower plan" do
    assert_predicate build_change, :valid?
  end

  test "requires an effective date" do
    change = build_change(effective_at: nil)

    assert_not_predicate change, :valid?
    assert_predicate change.errors[:effective_at], :present?
  end

  test "rejects a plan that is not lower than the current plan" do
    change = build_change(new_plan: @current_plan)

    assert_not_predicate change, :valid?
  end

  test "rejects a subscription without expiration" do
    @subscription.update!(expires_at: nil)

    assert_not_predicate build_change, :valid?
  end

  test "allows only one pending change per club" do
    build_change.save!
    duplicate = build_change

    assert_not_predicate duplicate, :valid?
  end

  test "keeps the active subscription unchanged while the change is pending" do
    change = build_change
    change.save!

    assert_predicate @subscription.reload, :active?
    assert_equal @current_plan, @subscription.plan
  end

  test "preserves applied and canceled states" do
    applied = build_change(status: :applied, applied_at: Time.current)
    canceled = build_change(status: :canceled, canceled_at: Time.current)

    assert_predicate applied, :valid?
    assert_predicate canceled, :valid?
  end

  private

  def build_change(attributes = {})
    SubscriptionChange.new({
      club: @club,
      club_subscription: @subscription,
      current_plan: @current_plan,
      new_plan: @future_plan,
      requested_by: @owner,
      change_type: :downgrade,
      status: :pending,
      effective_at: @subscription.expires_at
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
