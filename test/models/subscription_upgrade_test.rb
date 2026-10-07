require "test_helper"

class SubscriptionUpgradeTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "upgrade-model@example.com", password: "password123", name: "Owner", username: "upgrade_model_owner")
    @club = Club.create!(name: "Upgrade Model Club")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    @current_plan = Plan.create!(name: "Current Upgrade Plan", description: "Atual", price: 190, billing_period: :monthly, active: true)
    @new_plan = Plan.create!(name: "New Upgrade Plan", description: "Novo", price: 290, billing_period: :monthly, active: true)
    @current_subscription = ClubSubscription.create!(club: @club, plan: @current_plan, owner: @owner, status: :active, billing_period: :monthly, expires_at: 1.month.from_now)
    @new_subscription = ClubSubscription.create!(club: @club, plan: @new_plan, owner: @owner, status: :pending, billing_period: :monthly, expires_at: @current_subscription.expires_at)
  end

  test "supports upgrade lifecycle states" do
    SubscriptionUpgrade.statuses.each_key do |status|
      upgrade = build_upgrade(status: status)
      assert_predicate upgrade, :valid?
      assert upgrade.public_send("#{status}?")
    end
  end

  test "requires the new plan to be more expensive" do
    upgrade = build_upgrade(new_plan: @current_plan)

    assert_not_predicate upgrade, :valid?
    assert_predicate upgrade.errors[:new_plan], :present?
  end

  test "associates the current and pending subscriptions with the club" do
    upgrade = build_upgrade

    assert_equal @club, upgrade.club
    assert_equal @current_subscription, upgrade.current_subscription
    assert_equal @new_subscription, upgrade.new_subscription
  end

  private

  def build_upgrade(status: :pending_payment, new_plan: @new_plan)
    SubscriptionUpgrade.new(
      club: @club,
      current_subscription: @current_subscription,
      new_subscription: @new_subscription,
      current_plan: @current_plan,
      new_plan: new_plan,
      requested_by: @owner,
      status: status,
      original_amount: 190,
      credit_amount: 190,
      upgrade_amount: 100,
      period_started_at: 1.month.ago,
      period_ends_at: 1.month.from_now,
      external_reference: "club_upgrade:#{SecureRandom.uuid}"
    )
  end
end
