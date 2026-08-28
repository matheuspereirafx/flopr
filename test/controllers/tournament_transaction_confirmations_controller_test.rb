require "test_helper"

class TournamentTransactionConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "owner confirms a pending buy-in and registration" do
    sign_in @owner

    patch confirm_path

    assert_redirected_to club_tournament_transactions_path(@club, @tournament)
    assert_predicate @payment.reload, :paid?
    assert_not_nil @payment.paid_at
    assert_predicate @registration.reload, :confirmed?
  end

  test "admin confirms a pending recharge without changing the registration status" do
    payment_create_charge_option(tournament: @tournament, kind: :rebuy, amount: 40)
    recharge_payment = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @player,
      kind: :rebuy,
      status: :pending,
      amount: 40
    )
    sign_in @admin

    patch confirm_club_tournament_transaction_path(@club, @tournament, recharge_payment)

    assert_predicate recharge_payment.reload, :paid?
    assert_predicate @registration.reload, :pending?
  end

  test "dealer cannot confirm a payment" do
    sign_in @dealer

    assert_no_changes -> { @payment.reload.status } do
      patch confirm_path
    end

    assert_response :forbidden
  end

  test "player cannot confirm a payment" do
    sign_in @player

    assert_no_changes -> { @payment.reload.status } do
      patch confirm_path
    end

    assert_response :forbidden
  end

  test "cannot confirm a payment from another club" do
    sign_in @owner

    patch confirm_club_tournament_transaction_path(@other_club, @other_tournament, @other_payment)

    assert_response :not_found
    assert_predicate @other_payment.reload, :pending?
  end

  test "unauthenticated user is redirected to sign in" do
    patch confirm_path

    assert_redirected_to new_user_session_path
  end

  private

  def setup
    @club = payment_create_club(name: "Poker House")
    @other_club = payment_create_club(name: "Other Poker House")
    @owner = payment_create_user("owner-confirm@example.com")
    @admin = payment_create_user("admin-confirm@example.com")
    @dealer = payment_create_user("dealer-confirm@example.com")
    @player = payment_create_user("player-confirm@example.com")
    payment_create_membership(user: @owner, club: @club, role: :owner)
    payment_create_membership(user: @admin, club: @club, role: :admin)
    payment_create_membership(user: @dealer, club: @club, role: :dealer)
    payment_create_membership(user: @player, club: @club, role: :player)
    @tournament = payment_create_tournament(club: @club, name: "Main confirmation tournament")
    @other_tournament = payment_create_tournament(club: @other_club, name: "Other confirmation tournament")
    payment_create_charge_option(tournament: @tournament, kind: :buy_in, amount: 100)
    payment_create_charge_option(tournament: @other_tournament, kind: :buy_in, amount: 100)
    @registration = payment_create_registration(tournament: @tournament, user: @player, status: :pending)
    payment_create_registration(tournament: @other_tournament, user: @owner, status: :pending)
    @payment = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @player,
      status: :pending,
      amount: 100
    )
    @other_payment = payment_create_registration_payment(
      tournament: @other_tournament,
      user: @owner,
      recorded_by: @owner,
      status: :pending,
      amount: 100
    )
  end

  def confirm_path
    confirm_club_tournament_transaction_path(@club, @tournament, @payment)
  end
end
