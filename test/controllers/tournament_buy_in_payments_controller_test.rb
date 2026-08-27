require "test_helper"

class TournamentBuyInPaymentsControllerTest < ActionDispatch::IntegrationTest
  class GatewayStub
    def create_customer(_user)
      { id: "cus_buy_in_player" }
    end

    def create_payment(_registration, _charge_option, _customer_id)
      { id: "pay_buy_in_pix", status: "PENDING" }
    end
  end

  test "player can create a pending Pix buy-in payment" do
    @player.update!(cpf: "52998224725")
    sign_in @player

    with_gateway_stub do
      assert_difference "RegistrationPayment.count", 1 do
        post payment_path
      end
    end

    payment = RegistrationPayment.order(:created_at).last
    assert_predicate payment, :pending?
    assert_equal @buy_in.amount, payment.amount
    assert_equal "pay_buy_in_pix", payment.provider_payment_id
    assert_equal @player, payment.tournament_registration.user
    assert_predicate @registration.reload, :pending?
    assert_redirected_to club_tournament_path(@club, @tournament)
  end

  test "a second payment does not create a duplicate transaction" do
    @player.update!(cpf: "52998224725")
    @registration.update!(status: :confirmed)
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post payment_path
    end

    assert_redirected_to club_tournament_path(@club, @tournament)
  end

  test "a player without a registration cannot pay the buy-in" do
    @registration.destroy!
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post payment_path
    end

    assert_response :not_found
  end

  test "another club tournament cannot be accessed by changing ids" do
    sign_in @player

    post "/clubs/#{@other_club.id}/tournaments/#{@other_tournament.id}/buy_in_payment"

    assert_response :not_found
  end

  test "an unauthenticated user is redirected to sign in" do
    post payment_path

    assert_redirected_to new_user_session_path
  end

  private

  def setup
    @club = payment_create_club(name: "Poker House")
    @other_club = payment_create_club(name: "Other Poker House")
    @tournament = payment_create_tournament(club: @club, name: "Friday Buy-in")
    @other_tournament = payment_create_tournament(club: @other_club, name: "Other Buy-in")
    @player = payment_create_user("player-buy-in@example.com")
    @other_owner = payment_create_user("other-owner-buy-in@example.com")
    payment_create_membership(user: @player, club: @club, role: :player)
    payment_create_membership(user: @other_owner, club: @other_club, role: :owner)
    @buy_in = payment_create_charge_option(tournament: @tournament, kind: :buy_in, amount: 100)
    payment_create_charge_option(tournament: @other_tournament, kind: :buy_in, amount: 100)
    @registration = payment_create_registration(
      tournament: @tournament,
      user: @player,
      status: :pending
    )
  end

  def payment_path
    club_tournament_buy_in_payment_path(@club, @tournament)
  end

  def with_gateway_stub
    original_new = AsaasClient.method(:new)
    AsaasClient.define_singleton_method(:new) { GatewayStub.new }
    yield
  ensure
    AsaasClient.define_singleton_method(:new, original_new)
  end
end
