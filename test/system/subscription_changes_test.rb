require "application_system_test_case"

class SubscriptionChangesTest < ApplicationSystemTestCase
  setup do
    @club = Club.create!(name: "Subscription System Club")
    @owner = User.create!(
      name: "Subscription Owner",
      username: "subscription_owner",
      email: "subscription-owner@example.com",
      password: "password123"
    )
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

    sign_in_as_owner
  end

  test "owner confirms a downgrade in the confirmation modal on the subscription page" do
    visit new_club_subscription_path(plan_id: @future_plan.id)

    assert_text "Escolha o clube da assinatura"
    assert_text @current_plan.name
    assert_text @future_plan.name

    select @club.name, from: "club_id"
    click_button "Confirmar contratação"

    assert_selector "dialog[open]"
    assert_current_path new_club_subscription_path(plan_id: @future_plan.id)
    assert_text "Você está reduzindo o plano"
    assert_text "Não haverá reembolso automático"

    click_button "Confirmar downgrade"

    assert_text "Downgrade agendado para a próxima renovação."
    assert_predicate SubscriptionChange.order(:created_at).last, :pending?
  end

  test "owner cancels a pending downgrade from the subscription card" do
    change = SubscriptionChange.create!(
      club: @club,
      club_subscription: @subscription,
      current_plan: @current_plan,
      new_plan: @future_plan,
      requested_by: @owner,
      change_type: :downgrade,
      status: :pending,
      effective_at: @subscription.expires_at
    )

    visit club_subscriptions_path

    assert_text "Downgrade agendado"
    assert_text @future_plan.name

    accept_confirm do
      click_button "Cancelar downgrade"
    end

    assert_text "Downgrade cancelado."
    assert_predicate change.reload, :canceled?
  end

  private

  def sign_in_as_owner
    visit new_user_session_path
    fill_in "user_email", with: @owner.email
    fill_in "user_password", with: "password123"
    click_button "Entrar"
  end

  def create_plan(attributes)
    Plan.create!(
      name: attributes.fetch(:name),
      description: "Plano de teste",
      price: attributes.fetch(:price),
      billing_period: attributes.fetch(:billing_period),
      active: true,
      tier: attributes.fetch(:tier),
      features: attributes.fetch(:features)
    )
  end
end
