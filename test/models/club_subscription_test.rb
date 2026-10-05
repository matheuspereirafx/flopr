require "test_helper"

class ClubSubscriptionTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "subscription-owner@example.com", password: "password123", name: "Owner", username: "subscription_owner")
    @replacement_owner = User.create!(email: "replacement-owner@example.com", password: "password123", name: "Replacement", username: "replacement_owner")
    @club = Club.create!(name: "Subscription Club")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    @plan = Plan.create!(name: "Iniciante", description: "Plano inicial", price: 49, billing_period: "monthly", active: true)
  end

  test "requires a club, plan and historical owner" do
    subscription = ClubSubscription.new(status: :active, billing_period: "monthly")

    assert_not_predicate subscription, :valid?
    assert_predicate subscription.errors[:club], :present?
    assert_predicate subscription.errors[:plan], :present?
    assert_predicate subscription.errors[:owner], :present?
  end

  test "supports active, canceled and expired statuses" do
    %i[active canceled expired].each do |status|
      subscription = ClubSubscription.new(club: @club, plan: @plan, owner: @owner, status: status, billing_period: "monthly")

      assert_predicate subscription, :valid?
      assert subscription.public_send("#{status}?")
    end
  end

  test "copies the plan billing period to the subscription" do
    subscription = ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: @plan.billing_period)

    assert_equal @plan.billing_period, subscription.billing_period
  end

  test "allows a new active subscription after cancellation" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :canceled, billing_period: "monthly")

    subscription = ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: "monthly")

    assert_predicate subscription, :active?
  end

  test "allows a new active subscription after expiration" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :expired, billing_period: "monthly")

    subscription = ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: "monthly")

    assert_predicate subscription, :active?
  end

  test "does not allow two active subscriptions for the same club" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: "monthly")
    duplicate = ClubSubscription.new(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: "monthly")

    assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
  end

  test "keeps the historical owner when club ownership changes" do
    subscription = ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: "monthly")
    ClubMembership.where(club: @club, user: @owner).update!(role: :player)
    ClubMembership.create!(club: @club, user: @replacement_owner, role: :owner)

    assert_equal @owner.id, subscription.reload.owner_id
  end

  test "remains associated with the contracted plan" do
    subscription = ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :active, billing_period: "monthly")

    assert_equal @plan, subscription.reload.plan
  end
end
