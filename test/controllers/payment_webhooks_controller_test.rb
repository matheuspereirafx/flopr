require "test_helper"

class PaymentWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "confirms a buy-in when Asaas reports payment received" do
    payment = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @owner,
      status: :pending
    )
    payment.update!(provider: "asaas")
    payment.provider_payment_id = "pay_sandbox_buy_in"
    payment.save!

    post "/webhooks/asaas",
         params: {
           event: "PAYMENT_RECEIVED",
           payment: { id: payment.provider_payment_id }
         },
         headers: webhook_headers,
         as: :json

    assert_response :success
    assert_predicate payment.reload, :paid?
    assert_predicate @player.tournament_registrations.find_by!(tournament: @tournament), :confirmed?
  end

  test "processing the same webhook twice is idempotent" do
    payment = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @owner,
      status: :pending
    )
    payment.update!(provider: "asaas")
    payment.provider_payment_id = "pay_sandbox_duplicate"
    payment.save!
    payload = { event: "PAYMENT_RECEIVED", payment: { id: payment.provider_payment_id } }

    2.times { post "/webhooks/asaas", params: payload, headers: webhook_headers, as: :json }

    assert_equal 1, RegistrationPayment.where(provider_payment_id: payment.provider_payment_id).count
    assert_predicate payment.reload, :paid?
  end

  test "rejects a webhook with an invalid token without changing the payment" do
    payment = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @owner,
      status: :pending
    )
    payment.update!(provider: "asaas")
    payment.provider_payment_id = "pay_sandbox_invalid_token"
    payment.save!

    post "/webhooks/asaas",
         params: { event: "PAYMENT_RECEIVED", payment: { id: payment.provider_payment_id } },
         headers: { "asaas-access-token" => "invalid" },
         as: :json

    assert_includes [401, 403], response.status
    assert_predicate payment.reload, :pending?
  end

  private

  def setup
    ENV["ASAAS_WEBHOOK_TOKEN"] = "test-webhook-token"
    @club = payment_create_club
    @owner = payment_create_user("webhook-owner@example.com")
    @player = payment_create_user("webhook-player@example.com")
    payment_create_membership(user: @owner, club: @club, role: :owner)
    payment_create_membership(user: @player, club: @club, role: :player)
    @tournament = payment_create_tournament(club: @club)
    payment_create_charge_option(tournament: @tournament, kind: :buy_in)
    payment_create_registration(tournament: @tournament, user: @player, status: :pending)
  end

  def webhook_headers
    { "asaas-access-token" => "test-webhook-token" }
  end
end
