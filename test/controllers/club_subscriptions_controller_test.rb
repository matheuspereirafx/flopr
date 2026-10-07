require "test_helper"

class AsaasSubscriptionServiceDouble
  attr_reader :calls

  def initialize(response)
    @response = response
    @calls = []
  end

  def create_subscription(plan, club)
    @calls << [plan, club]
    @response
  end
end

class AsaasPaymentServiceDouble
  attr_reader :calls

  def initialize(payment_id = "pay_upgrade")
    @payment_id = payment_id
    @calls = []
  end

  def create_upgrade_payment(upgrade)
    @calls << upgrade
    @payment_id
  end
end

module Asaas
  class SubscriptionService
    class << self
      attr_accessor :test_double
    end

    def self.new(*)
      test_double || AsaasSubscriptionServiceDouble.new(
        customer_id: "cus_default",
        subscription_id: "sub_default"
      )
    end
  end

  class PaymentService
    class << self
      attr_accessor :test_double
    end

    def self.new(*)
      test_double || AsaasPaymentServiceDouble.new
    end
  end
end

class ClubSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    Asaas::SubscriptionService.test_double = nil
    Asaas::PaymentService.test_double = nil
  end

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
    assert_select "main[data-subscription-flow-new-plan-id-value='#{@plan.id}']", count: 1
    assert_select "main[data-subscription-flow-quote-url-value='#{club_subscription_quote_path}']", count: 1
    assert_select "option[value='#{@club.id}']", count: 1
    assert_select "option[value='#{@second_club.id}']", count: 1
    assert_select "option[value='#{@other_club.id}']", count: 0
  end

  test "returns the full price for an initial subscription quote" do
    sign_in @owner

    get club_subscription_quote_path,
        params: { club_id: @club.id, plan_id: @plan.id },
        headers: { "ACCEPT" => "application/json" }

    assert_response :success
    quote = JSON.parse(response.body)
    assert_equal "initial", quote.fetch("mode")
    assert_equal true, quote.fetch("eligible")
    assert_equal 0.0, quote.fetch("credit_amount")
    assert_equal 49.0, quote.fetch("amount_due")
  end

  test "returns the proportional amount for a paid upgrade quote" do
    current_plan = Plan.create!(name: "Current #{SecureRandom.hex(4)}", description: "Atual", price: 190, billing_period: "monthly", active: true)
    next_plan = Plan.create!(name: "Next #{SecureRandom.hex(4)}", description: "Novo", price: 290, billing_period: "monthly", active: true)
    ClubSubscription.create!(
      club: @club,
      plan: current_plan,
      owner: @owner,
      status: :active,
      billing_period: current_plan.billing_period,
      expires_at: 1.month.from_now
    )
    sign_in @owner

    get club_subscription_quote_path,
        params: { club_id: @club.id, plan_id: next_plan.id },
        headers: { "ACCEPT" => "application/json" }

    assert_response :success
    quote = JSON.parse(response.body)
    assert_equal "upgrade", quote.fetch("mode")
    assert_equal true, quote.fetch("eligible")
    assert_in_delta 100.0, quote.fetch("amount_due"), 1.0
    assert_operator quote.fetch("credit_amount"), :>, 0.0
  end

  test "rejects a monthly to yearly upgrade quote until its proration rule is defined" do
    current_plan = Plan.create!(name: "Monthly Current #{SecureRandom.hex(4)}", description: "Atual", price: 190, billing_period: "monthly", active: true)
    yearly_plan = Plan.create!(name: "Yearly New #{SecureRandom.hex(4)}", description: "Novo", price: 2_436, billing_period: "yearly", active: true)
    ClubSubscription.create!(
      club: @club,
      plan: current_plan,
      owner: @owner,
      status: :active,
      billing_period: current_plan.billing_period,
      expires_at: 1.month.from_now
    )
    sign_in @owner

    get club_subscription_quote_path,
        params: { club_id: @club.id, plan_id: yearly_plan.id },
        headers: { "ACCEPT" => "application/json" }

    assert_response :success
    quote = JSON.parse(response.body)
    assert_equal "incompatible_cycle", quote.fetch("mode")
    assert_equal false, quote.fetch("eligible")
    assert_equal "A troca entre ciclos mensal e anual ainda não está disponível.", quote.fetch("message")
  end

  test "owner can navigate between monthly and yearly options" do
    yearly_plan = Plan.create!(name: "Iniciante Anual", description: "Plano anual", price: 411, billing_period: "yearly", active: true)
    sign_in @owner

    get new_club_subscription_path(plan_id: @plan.id)

    assert_response :success
    assert_select "a[href='#{new_club_subscription_path(plan_id: @plan.id)}']", text: "Mensal", count: 1
    assert_select "a[href='#{new_club_subscription_path(plan_id: yearly_plan.id)}']", text: "Anual", count: 1
  end

  test "admin can see and contract a plan for the club" do
    sign_in @admin
    get new_club_subscription_path(plan_id: @plan.id)

    assert_response :success
    assert_select "option[value='#{@club.id}']", count: 1

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_redirected_to clubs_path
  end

  test "exposes the current plan price for downgrade detection" do
    lower_plan = Plan.create!(name: "Free", description: "Plano gratuito", price: 0, billing_period: "monthly", active: true)
    ClubSubscription.create!(
      club: @club,
      plan: @plan,
      owner: @owner,
      status: :active,
      billing_period: @plan.billing_period,
      expires_at: 1.month.from_now
    )
    sign_in @owner

    get new_club_subscription_path(plan_id: lower_plan.id)

    assert_response :success
    assert_select "option[value='#{@club.id}'][data-current-plan-price='49.0']", count: 1
    assert_select "option[value='#{@club.id}'][data-downgrade-path='#{club_subscription_change_path(@club)}']", count: 1
  end

  test "owner sees the current subscription for each owned club" do
    ClubSubscription.create!(
      club: @club,
      plan: @plan,
      owner: @owner,
      status: :active,
      billing_period: @plan.billing_period
    )
    sign_in @owner

    get club_subscriptions_path

    assert_response :success
    assert_select ".club-subscription-card", count: 2
    assert_select ".club-subscription-card", text: /#{@club.name}/
    assert_select ".club-subscription-card", text: /#{@plan.name}/
    assert_select ".club-subscription-card", text: /R\$ 49,00 \/ mês/
    assert_select ".club-subscription-card", text: /Não definida/
    assert_select ".club-subscription-card", text: /#{@second_club.name}/
    assert_select ".club-subscription-card", text: /Nenhuma assinatura ativa/
    assert_select "a[href='#{root_path(anchor: 'planos')}']", text: "Mudar assinatura", count: 1
  end

  test "owner creates a pending subscription for the selected club" do
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
    assert_predicate subscription, :pending?
    assert_equal @plan.billing_period, subscription.billing_period
    assert_nil subscription.expires_at
  end

  test "owner creates a yearly subscription without activating it before payment" do
    yearly_plan = Plan.create!(name: "Iniciante Anual", description: "Plano anual", price: 411, billing_period: "yearly", active: true)
    sign_in @owner

    post club_subscriptions_path, params: { plan_id: yearly_plan.id, club_id: @club.id }

    assert_redirected_to clubs_path
    subscription = ClubSubscription.order(:created_at).last
    assert_equal yearly_plan, subscription.plan
    assert_equal "yearly", subscription.billing_period
    assert_predicate subscription, :pending?
    assert_nil subscription.expires_at
  end

  test "does not accept a forged expiration date" do
    sign_in @owner
    forged_expiration = 10.years.from_now

    post club_subscriptions_path, params: {
      plan_id: @plan.id,
      club_id: @club.id,
      expires_at: forged_expiration
    }

    subscription = ClubSubscription.order(:created_at).last
    assert_nil subscription.expires_at
  end

  test "does not create a duplicate subscription for the current active plan" do
    ClubSubscription.create!(
      club: @club,
      plan: @plan,
      owner: @owner,
      status: :active,
      billing_period: @plan.billing_period
    )
    sign_in @owner

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_redirected_to club_subscriptions_path
    follow_redirect!
    assert_select ".alert", text: /já possui este plano ativo/
  end

  test "confirms a successful subscription" do
    sign_in @owner
    post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }

    follow_redirect!

    assert_select ".alert", text: /cobrança|aguardando/i
  end

  test "does not create a subscription for a club owned by another user" do
    sign_in @owner

    assert_no_difference("ClubSubscription.count") do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @other_club.id }
    end

    assert_response :not_found
  end

  %i[dealer player].each do |role|
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
    assert_predicate subscription, :pending?
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
    assert_predicate current_subscription.reload, :active?
    assert_predicate ClubSubscription.order(:created_at).last, :pending?
  end

  test "creates a proportional upgrade payment for a paid current plan" do
    current_plan = Plan.create!(name: "Iniciante #{SecureRandom.hex(4)}", description: "Plano atual", price: 190, billing_period: "monthly", active: true)
    professional_plan = Plan.create!(name: "Profissional #{SecureRandom.hex(4)}", description: "Plano novo", price: 290, billing_period: "monthly", active: true)
    ClubSubscription.create!(
      club: @club,
      plan: current_plan,
      owner: @owner,
      status: :active,
      billing_period: current_plan.billing_period,
      expires_at: 1.month.from_now
    )
    payment_service = AsaasPaymentServiceDouble.new("pay_upgrade_test")
    Asaas::PaymentService.test_double = payment_service
    sign_in @owner

    assert_difference(["ClubSubscription.count", "SubscriptionUpgrade.count"], 1) do
      post club_subscriptions_path, params: { plan_id: professional_plan.id, club_id: @club.id }
    end

    assert_redirected_to clubs_path
    upgrade = SubscriptionUpgrade.order(:created_at).last
    assert_equal 100.to_d, upgrade.upgrade_amount
    assert_equal "pay_upgrade_test", upgrade.asaas_payment_id
    assert_predicate upgrade.new_subscription.reload, :pending?
    assert_equal 1, payment_service.calls.size
  end

  test "allows a new subscription after the previous one was canceled" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :canceled, billing_period: @plan.billing_period)
    sign_in @owner

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_predicate ClubSubscription.order(:created_at).last, :pending?
  end

  test "allows a new subscription after the previous one expired" do
    ClubSubscription.create!(club: @club, plan: @plan, owner: @owner, status: :expired, billing_period: @plan.billing_period)
    sign_in @owner

    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: { plan_id: @plan.id, club_id: @club.id }
    end

    assert_predicate ClubSubscription.order(:created_at).last, :pending?
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

  test "starts a pending external subscription without trusting sensitive parameters" do
    sign_in @owner
    service = AsaasSubscriptionServiceDouble.new(
      customer_id: "cus_created",
      subscription_id: "sub_created"
    )

    Asaas::SubscriptionService.test_double = service
    assert_difference("ClubSubscription.count", 1) do
      post club_subscriptions_path, params: {
        plan_id: @plan.id,
        club_id: @club.id,
        owner_id: @outsider.id,
        status: "active",
        billing_period: "yearly",
        price: 0,
        asaas_customer_id: "cus_forged",
        asaas_subscription_id: "sub_forged"
      }
    end
    Asaas::SubscriptionService.test_double = nil

    subscription = ClubSubscription.order(:created_at).last
    assert_predicate subscription, :pending?
    assert_equal "sub_created", subscription.asaas_subscription_id
    assert_equal @owner, subscription.owner
    assert_equal @plan.billing_period, subscription.billing_period
    assert_equal [[@plan, @club]], service.calls
  end

  test "does not cancel the current subscription before the new payment is approved" do
    current_subscription = ClubSubscription.create!(
      club: @club,
      plan: @plan,
      owner: @owner,
      status: :active,
      billing_period: @plan.billing_period,
      expires_at: 1.month.from_now
    )
    next_plan = Plan.create!(
      name: "Next Plan #{SecureRandom.hex(4)}",
      description: "Próximo plano",
      price: 99,
      billing_period: :monthly,
      active: true
    )
    service = AsaasSubscriptionServiceDouble.new(
      customer_id: "cus_created",
      subscription_id: "sub_created"
    )
    payment_service = AsaasPaymentServiceDouble.new("pay_pending_upgrade")
    sign_in @owner

    Asaas::SubscriptionService.test_double = service
    Asaas::PaymentService.test_double = payment_service
    post club_subscriptions_path, params: { plan_id: next_plan.id, club_id: @club.id }
    Asaas::SubscriptionService.test_double = nil
    Asaas::PaymentService.test_double = nil

    assert_predicate current_subscription.reload, :active?
    assert_empty service.calls
    assert_equal 1, payment_service.calls.size
    assert_predicate SubscriptionUpgrade.order(:created_at).last, :pending_payment?
  end

  test "rejects a monthly to yearly upgrade until its proration rule is defined" do
    current_plan = Plan.create!(name: "Monthly Current #{SecureRandom.hex(4)}", description: "Atual", price: 190, billing_period: "monthly", active: true)
    yearly_plan = Plan.create!(name: "Yearly New #{SecureRandom.hex(4)}", description: "Novo", price: 2_436, billing_period: "yearly", active: true)
    ClubSubscription.create!(
      club: @club,
      plan: current_plan,
      owner: @owner,
      status: :active,
      billing_period: current_plan.billing_period,
      expires_at: 1.month.from_now
    )
    sign_in @owner

    assert_no_difference(["ClubSubscription.count", "SubscriptionUpgrade.count"]) do
      post club_subscriptions_path, params: { plan_id: yearly_plan.id, club_id: @club.id }
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
