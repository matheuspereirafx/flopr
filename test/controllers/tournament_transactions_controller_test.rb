require "test_helper"

class TournamentTransactionsControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to sign in" do
    get transactions_path(@club, @tournament)

    assert_redirected_to new_user_session_path
  end

  test "owner can view all transactions for the tournament" do
    payment = create_payment_for(@player, status: :paid, amount: 50)
    sign_in @owner

    get transactions_path(@club, @tournament)

    assert_response :success
    assert_includes response.body, payment.amount.to_s
    assert_includes response.body, @player.name
    assert_includes response.body, "Pago"
    assert_not_includes response.body, "Responsável"
    assert_select ".mobile-completed-transactions", count: 1
    assert_select ".mobile-completed-transaction", count: 1
  end

  test "admin can view all transactions for the tournament" do
    create_payment_for(@player)
    sign_in @admin

    get transactions_path(@club, @tournament)

    assert_response :success
  end

  test "displays pending payment status in Portuguese" do
    create_payment_for(@player, status: :pending)
    sign_in @owner

    get transactions_path(@club, @tournament)

    assert_response :success
    assert_includes response.body, "Pendente"
    assert_select ".mobile-transaction-card", count: 1
  end

  test "displays the exact payment approval time" do
    payment = create_payment_for(@player)
    payment_time = Time.zone.local(2026, 8, 20, 15, 45, 12)
    payment.update!(paid_at: payment_time)
    sign_in @owner

    get transactions_path(@club, @tournament)

    assert_response :success
    assert_includes response.body, payment_time.iso8601
    assert_includes response.body, payment_time.strftime("%H:%M")
  end

  test "dealer cannot view administrative transactions" do
    sign_in @dealer

    get transactions_path(@club, @tournament)

    assert_response :forbidden
  end

  test "player cannot view administrative transactions" do
    sign_in @player

    get transactions_path(@club, @tournament)

    assert_response :forbidden
  end

  test "user without membership cannot view transactions" do
    sign_in @outsider

    get transactions_path(@club, @tournament)

    assert_response :not_found
  end

  test "changing the club id cannot expose transactions from another club" do
    sign_in @owner

    get transactions_path(@other_club, @other_tournament)

    assert_response :not_found
  end

  test "changing the tournament id cannot expose transactions from another club" do
    sign_in @owner

    get transactions_path(@club, @other_tournament)

    assert_response :not_found
  end

  test "only transactions from the current tournament are displayed" do
    current_payment = create_payment_for(@player)
    create_payment_for(@outsider, tournament: @other_tournament, amount: 75)
    sign_in @owner

    get transactions_path(@club, @tournament)

    assert_response :success
    assert_includes response.body, current_payment.amount.to_s
    assert_not_includes response.body, @outsider.name
  end

  test "query parameters cannot change transaction scope or mutate the database" do
    create_payment_for(@player)
    sign_in @owner
    counts_before = [User.count, Club.count, Tournament.count, RegistrationPayment.count]

    get transactions_path(
      @club,
      @tournament,
      user_id: @outsider.id,
      club_id: @other_club.id,
      tournament_id: @other_tournament.id,
      status: "paid",
      role: "owner"
    )

    assert_response :success
    assert_equal counts_before,
                 [User.count, Club.count, Tournament.count, RegistrationPayment.count]
  end

  test "invalid ids return not found" do
    sign_in @owner

    get transactions_path_struct("invalid", "invalid")

    assert_response :not_found
  end

  test "only GET is supported and no write occurs" do
    sign_in @owner
    counts_before = RegistrationPayment.count

    post transactions_path(@club, @tournament), params: {
      registration_payment: {
        amount: 999,
        status: "paid",
        user_id: @outsider.id,
        recorded_by_id: @outsider.id
      }
    }

    assert_response :not_found
    assert_equal counts_before, RegistrationPayment.count
  end

  private

  def setup
    @club = payment_create_club(name: "Poker House")
    @other_club = payment_create_club(name: "Other Poker House")
    @tournament = payment_create_tournament(club: @club, name: "Friday Transactions")
    @other_tournament = payment_create_tournament(club: @other_club, name: "Other Transactions")

    @owner = payment_create_user("owner-transactions@example.com")
    @admin = payment_create_user("admin-transactions@example.com")
    @dealer = payment_create_user("dealer-transactions@example.com")
    @player = payment_create_user("player-transactions@example.com")
    @outsider = payment_create_user("outsider-transactions@example.com")

    payment_create_membership(user: @owner, club: @club, role: :owner)
    payment_create_membership(user: @admin, club: @club, role: :admin)
    payment_create_membership(user: @dealer, club: @club, role: :dealer)
    payment_create_membership(user: @player, club: @club, role: :player)
    payment_create_membership(user: @outsider, club: @other_club, role: :owner)

    [@tournament, @other_tournament].each do |tournament|
      payment_create_charge_option(tournament: tournament)
    end
    payment_create_registration(tournament: @tournament, user: @player)
    payment_create_registration(tournament: @other_tournament, user: @outsider)
  end

  def create_payment_for(user, tournament: @tournament, status: :paid, amount: 50)
    payment_create_registration_payment(
      tournament: tournament,
      user: user,
      recorded_by: @owner,
      status: status,
      amount: amount
    )
  end

  def transactions_path_struct(club_id, tournament_id)
    "/clubs/#{club_id}/tournaments/#{tournament_id}/transactions"
  end
end
