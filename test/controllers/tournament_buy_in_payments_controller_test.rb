require "test_helper"

class TournamentBuyInPaymentsControllerTest < ActionDispatch::IntegrationTest
  test "player informs a manual buy-in payment" do
    sign_in @player

    assert_difference "RegistrationPayment.count", 1 do
      post payment_path
    end

    payment = RegistrationPayment.order(:created_at).last
    assert_predicate payment, :pending?
    assert_predicate payment, :manual?
    assert_equal "manual", payment.provider
    assert_equal @buy_in.amount, payment.amount
    assert_equal @player, payment.recorded_by
    assert_predicate @registration.reload, :pending?
    assert_redirected_to club_tournament_path(@club, @tournament, payment: "buy_in")
  end

  test "does not duplicate a pending buy-in payment" do
    sign_in @player
    post payment_path

    assert_no_difference "RegistrationPayment.count" do
      post payment_path
    end

    assert_redirected_to club_tournament_path(@club, @tournament, payment: "buy_in")
  end

  test "does not create a payment for a confirmed registration" do
    @registration.update!(status: :confirmed)
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post payment_path
    end

    assert_redirected_to club_tournament_path(@club, @tournament)
  end

  test "does not create a payment without an active buy-in" do
    @buy_in.update!(active: false)
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post payment_path
    end

    assert_redirected_to club_tournament_path(@club, @tournament, payment: "buy_in")
  end

  test "player without a registration cannot inform a payment" do
    @registration.destroy!
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post payment_path
    end

    assert_response :not_found
  end

  test "another club tournament cannot be accessed by changing ids" do
    sign_in @player

    assert_no_difference "RegistrationPayment.count" do
      post club_tournament_buy_in_payment_path(@other_club, @other_tournament)
    end

    assert_response :not_found
  end

  test "unauthenticated user is redirected to sign in" do
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
    @registration = payment_create_registration(tournament: @tournament, user: @player, status: :pending)
  end

  def payment_path
    club_tournament_buy_in_payment_path(@club, @tournament)
  end
end
