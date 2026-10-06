require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "belongs to no club because plans are global" do
    plan = Plan.new(valid_plan_attributes)

    assert_respond_to plan, :club_subscriptions
    assert_not_respond_to plan, :club
  end

  test "is valid with the required configuration" do
    plan = Plan.new(valid_plan_attributes)

    assert_predicate plan, :valid?
  end

  test "requires name, price and billing period" do
    plan = Plan.new(valid_plan_attributes.except(:name, :price, :billing_period))

    assert_not_predicate plan, :valid?
    assert_predicate plan.errors[:name], :present?
    assert_predicate plan.errors[:price], :present?
    assert_predicate plan.errors[:billing_period], :present?
  end

  test "does not accept a negative price" do
    plan = Plan.new(valid_plan_attributes.merge(price: -1))

    assert_not_predicate plan, :valid?
  end

  test "calculates a yearly expiration twelve months after the start" do
    plan = Plan.new(valid_plan_attributes.merge(billing_period: "yearly", price: 840))
    started_at = Time.zone.parse("2026-10-05 12:00:00")

    assert_equal started_at + 1.year, plan.subscription_expires_at(started_at)
  end

  test "calculates a monthly expiration one month after the start" do
    plan = Plan.new(valid_plan_attributes.merge(billing_period: "monthly", price: 100))
    started_at = Time.zone.parse("2026-10-05 12:00:00")

    assert_equal started_at + 1.month, plan.subscription_expires_at(started_at)
  end

  test "does not expire the free plan" do
    plan = Plan.new(valid_plan_attributes)

    assert_nil plan.subscription_expires_at
  end

  test "uses canonical limits for legacy plan prices" do
    assert_equal 4, Plan.new(valid_plan_attributes.merge(name: "Iniciante", price: 49)).monthly_tournament_limit
    assert_equal 9, Plan.new(valid_plan_attributes.merge(name: "Profissional", price: 119)).monthly_tournament_limit
  end

  test "stores plan features as an array" do
    plan = Plan.new(valid_plan_attributes.merge(features: %w[invitations guest_list]))

    assert plan.valid?
    assert_equal %w[invitations guest_list], plan.features
  end

  test "identifies a lower plan regardless of its price" do
    current_plan = build_plan(name: "Profissional Anual", price: 1_000, billing_period: :yearly, tier: 2,
                              features: %w[invitations guest_list buy_ins transactions prize_pool])
    future_plan = build_plan(name: "Iniciante Mensal", price: 100, billing_period: :monthly, tier: 1,
                             features: %w[invitations guest_list])

    assert current_plan.downgrade_to?(future_plan)
  end

  test "identifies a change from yearly to monthly in the same tier as a downgrade" do
    current_plan = build_plan(name: "Profissional Anual", price: 1_000, billing_period: :yearly, tier: 2)
    future_plan = build_plan(name: "Profissional Mensal", price: 100, billing_period: :monthly, tier: 2)

    assert current_plan.downgrade_to?(future_plan)
  end

  test "does not identify an upgrade as a downgrade" do
    current_plan = build_plan(name: "Iniciante Mensal", price: 100, billing_period: :monthly, tier: 1,
                              features: %w[invitations])
    future_plan = build_plan(name: "Profissional Mensal", price: 200, billing_period: :monthly, tier: 2,
                             features: %w[invitations guest_list buy_ins transactions prize_pool])

    assert_not current_plan.downgrade_to?(future_plan)
  end

  test "does not identify the same plan as a downgrade" do
    plan = build_plan(name: "Iniciante Mensal", price: 100, billing_period: :monthly, tier: 1)

    assert_not plan.downgrade_to?(plan)
  end

  test "active scope returns only active plans" do
    active_plan = Plan.create!(valid_plan_attributes)
    Plan.create!(valid_plan_attributes.merge(name: "Inativo", active: false))

    assert_equal [active_plan], Plan.active.to_a
  end

  private

  def build_plan(attributes = {})
    Plan.new(valid_plan_attributes.merge(attributes))
  end

  def valid_plan_attributes
    {
      name: "Free",
      description: "Plano gratuito",
      price: 0,
      billing_period: "monthly",
      active: true
    }
  end
end
