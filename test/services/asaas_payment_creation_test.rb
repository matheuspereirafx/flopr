require "test_helper"

class AsaasPaymentCreationTest < ActiveSupport::TestCase
  class GatewayStub
    def initialize(response)
      @response = response
    end

    def create_payment(*_arguments)
      @response
    end

    def pix_qr_code(*_arguments)
      {
        encodedImage: "encoded-pix-image",
        payload: "pix-payload",
        expirationDate: "2026-08-27T23:59:59Z"
      }
    end
  end

  test "creates a pending Pix payment using the charge option amount" do
    user = payment_create_user("asaas-payment-player@example.com")
    registration = payment_create_registration(
      tournament: @tournament,
      user: user,
      status: :pending
    )
    gateway = GatewayStub.new(
      id: "pay_pix_123",
      billing_type: "PIX",
      value: @buy_in.amount
    )

    payment = AsaasPaymentCreation.call(
      registration: registration,
      charge_option: @buy_in,
      customer_id: "cus_player",
      payment_method: :pix,
      gateway: gateway
    )

    assert_predicate payment, :pending?
    assert_equal "pay_pix_123", payment.provider_payment_id
    assert_equal @buy_in.amount, payment.amount
    assert_equal "encoded-pix-image", payment.pix_qr_code_image
    assert_equal "pix-payload", payment.pix_payload
  end

  test "does not create a payment with a missing customer" do
    registration = @tournament.tournament_registrations.find_by!(user: @player)

    assert_raises(AsaasPaymentCreation::InvalidPayment) do
      AsaasPaymentCreation.call(
        registration: registration,
        charge_option: @buy_in,
        customer_id: nil,
        payment_method: :pix,
        gateway: GatewayStub.new({})
      )
    end
  end

  private

  def setup
    @club = payment_create_club
    @owner = payment_create_user("asaas-payment-owner@example.com")
    @player = payment_create_user("asaas-payment-existing-player@example.com")
    payment_create_membership(user: @owner, club: @club, role: :owner)
    payment_create_membership(user: @player, club: @club, role: :player)
    @tournament = payment_create_tournament(club: @club)
    @buy_in = payment_create_charge_option(tournament: @tournament, kind: :buy_in, amount: 100)
    payment_create_registration(tournament: @tournament, user: @player, status: :pending)
  end
end
