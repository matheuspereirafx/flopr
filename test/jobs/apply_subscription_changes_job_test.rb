require "test_helper"

class AsaasSubscriptionServiceDowngradeDouble
  attr_reader :canceled_ids, :created_subscriptions

  def initialize
    @canceled_ids = []
    @created_subscriptions = []
  end

  def cancel_subscription(subscription_id)
    @canceled_ids << subscription_id
  end

  def create_subscription(plan, club, next_due_date:, external_reference:)
    @created_subscriptions << [plan, club, next_due_date, external_reference]
    { customer_id: "cus_downgrade", subscription_id: "sub_downgrade" }
  end
end

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
      expires_at: @effective_at,
      asaas_subscription_id: "sub_current_downgrade"
    )
    @asaas_service = AsaasSubscriptionServiceDowngradeDouble.new
    stub_asaas_subscription_service(@asaas_service)
  end

  teardown do
    restore_asaas_subscription_service
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
    assert_equal "sub_downgrade", new_subscription.asaas_subscription_id
    assert_equal ["sub_current_downgrade"], @asaas_service.canceled_ids
    assert_equal [
      [@future_plan, @club, Date.current, "club:#{@club.id}:downgrade:#{change.id}"]
    ], @asaas_service.created_subscriptions
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

  test "cancels the provider recurrence without creating a new one for a free downgrade" do
    free_plan = create_plan(
      name: "Free",
      price: 0,
      billing_period: :monthly,
      tier: 0,
      features: []
    )
    change = create_change(new_plan: free_plan)

    ApplySubscriptionChangesJob.perform_now

    new_subscription = @club.reload.active_club_subscription
    assert_equal free_plan, new_subscription.plan
    assert_nil new_subscription.asaas_subscription_id
    assert_equal ["sub_current_downgrade"], @asaas_service.canceled_ids
    assert_empty @asaas_service.created_subscriptions
    assert_predicate change.reload, :applied?
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

  def stub_asaas_subscription_service(service)
    service_class = Asaas::SubscriptionService
    singleton_class = class << service_class; self; end
    @original_subscription_service_new = singleton_class.instance_method(:new)
    singleton_class.define_method(:new) { |**| service }
  end

  def restore_asaas_subscription_service
    service_class = Asaas::SubscriptionService
    singleton_class = class << service_class; self; end
    singleton_class.define_method(:new, @original_subscription_service_new)
  end
end
