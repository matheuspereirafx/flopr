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

  test "active scope returns only active plans" do
    active_plan = Plan.create!(valid_plan_attributes)
    Plan.create!(valid_plan_attributes.merge(name: "Inativo", active: false))

    assert_equal [active_plan], Plan.active.to_a
  end

  private

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
