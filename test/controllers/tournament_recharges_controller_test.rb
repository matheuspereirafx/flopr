require "test_helper"

class TournamentRechargesControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to sign in" do
    get recharges_path

    assert_redirected_to new_user_session_path
  end

  test "confirmed player can view available recharges and own history" do
    recharge = create_payment_for(@player, status: :pending, kind: :rebuy)
    sign_in @player

    get recharges_path

    assert_response :success
    assert_includes response.body, "Rebuy"
    assert_includes response.body, "Fichas"
    assert_not_includes response.body, ">Chips<"
    assert_includes response.body, recharge.created_at.in_time_zone("America/Sao_Paulo").strftime("%H:%M")
    assert_includes response.body, "Pendente"
    assert_select ".recharge-history-item__payment-details", text: /50/
    assert_select ".recharge-history-item__payment-details", text: /10.000 fichas/
    assert_includes response.body, "Ações de recargas"
    assert_includes response.body, "Histórico de recargas"
    assert_not_includes response.body, @other_player.name
  end

  test "confirmed player sees the club PIX key in the recharge modal" do
    @club.update!(pix_key: "pix@example.com", pix_key_type: "email", pix_recipient_name: "Poker House")
    sign_in @player

    get recharges_path

    assert_response :success
    assert_includes response.body, "pix@example.com"
    assert_includes response.body, "Poker House"
    assert_includes response.body, "Copiar chave PIX"
  end

  test "owner, admin and dealer cannot access the player page" do
    [@owner, @admin, @dealer].each do |user|
      sign_in user

      get recharges_path

      assert_response :forbidden
      sign_out user
    end
  end

  test "user without membership cannot access recharges" do
    sign_in @outsider

    get recharges_path

    assert_response :not_found
  end

  test "changing the club or tournament id cannot expose another club" do
    sign_in @player

    get recharges_path(club_id: @other_club.id, tournament_id: @other_tournament.id)

    assert_response :not_found
  end

  test "player can create a pending recharge for an available option" do
    sign_in @player
    counts_before = RegistrationPayment.count

    post recharges_path,
         params: {
           registration_payment: {
             tournament_charge_option_id: @rebuy.id,
             user_id: @outsider.id,
             status: "paid",
             amount: 999
           }
         }

    assert_redirected_to recharges_path
    assert_equal counts_before + 1, RegistrationPayment.count

    payment = @player.tournament_registrations.first.registration_payments.order(:created_at).last
    assert_predicate payment, :pending?
    assert_equal @player, payment.recorded_by
    assert_equal @rebuy, payment.tournament_charge_option
    assert_equal @rebuy.amount, payment.amount
  end

  test "player can add the fee to a recharge and the payments share a group" do
    sign_in @player

    assert_difference "RegistrationPaymentGroup.count", 1 do
      assert_difference "RegistrationPayment.count", 2 do
        post recharges_path,
             params: {
               registration_payment: {
                 tournament_charge_option_id: @rebuy.id,
                 include_fee: "1"
               }
             }
      end
    end

    group = @player.tournament_registrations.first.registration_payment_groups.order(:created_at).last
    assert_equal 125.to_d, group.total_amount
    assert_equal 20_000, group.total_chip_amount
    assert_equal %w[fee rebuy], group.registration_payments.map { |payment| payment.tournament_charge_option.kind }.sort
    assert group.registration_payments.all?(&:pending?)
  end

  test "player cannot request another recharge during the five second cooldown" do
    payment = create_payment_for(@player, status: :pending, kind: :rebuy)
    payment.update_column(:created_at, 1.second.ago)
    sign_in @player
    counts_before = RegistrationPayment.count

    get recharges_path

    assert_response :success
    assert_includes response.body, "Aguarde alguns segundos antes de solicitar outra recarga."
    assert_select ".recharge-option-card__button[disabled]", count: 0

    post recharges_path,
         params: {
           registration_payment: { tournament_charge_option_id: @addon.id }
         }

    assert_redirected_to recharges_path
    assert_equal counts_before, RegistrationPayment.count
    assert_equal "Aguarde alguns segundos antes de solicitar outra recarga.",
                 flash[:alert]
  end

  test "player can request another recharge after five seconds even if the previous one is pending" do
    payment = create_payment_for(@player, status: :pending, kind: :rebuy)
    payment.update_column(:created_at, 6.seconds.ago)
    sign_in @player

    assert_difference "RegistrationPayment.count", 1 do
      post recharges_path,
           params: {
             registration_payment: { tournament_charge_option_id: @addon.id }
           }
    end

    assert_redirected_to recharges_path
  end

  test "player cannot create a recharge for another tournament" do
    sign_in @player
    counts_before = RegistrationPayment.count

    post recharges_path,
         params: {
           registration_payment: {
             tournament_charge_option_id: @other_rebuy.id
           }
         }

    assert_redirected_to recharges_path
    assert_equal counts_before, RegistrationPayment.count
  end

  private

  def setup
    @club = payment_create_club(name: "Poker House")
    @other_club = payment_create_club(name: "Other Poker House")
    @tournament = payment_create_tournament(club: @club, name: "Friday Recharges")
    @other_tournament = payment_create_tournament(club: @other_club, name: "Other Recharges")

    @owner = payment_create_user("owner-recharges@example.com")
    @admin = payment_create_user("admin-recharges@example.com")
    @dealer = payment_create_user("dealer-recharges@example.com")
    @player = payment_create_user("player-recharges@example.com")
    @other_player = payment_create_user("other-player-recharges@example.com")
    @outsider = payment_create_user("outsider-recharges@example.com")

    payment_create_membership(user: @owner, club: @club, role: :owner)
    payment_create_membership(user: @admin, club: @club, role: :admin)
    payment_create_membership(user: @dealer, club: @club, role: :dealer)
    payment_create_membership(user: @player, club: @club, role: :player)
    payment_create_membership(user: @other_player, club: @other_club, role: :player)
    payment_create_membership(user: @outsider, club: @other_club, role: :owner)

    payment_create_charge_option(tournament: @tournament, kind: :buy_in)
    @rebuy = payment_create_charge_option(tournament: @tournament, kind: :rebuy, amount: 100)
    @addon = payment_create_charge_option(tournament: @tournament, kind: :addon, amount: 50)
    payment_create_charge_option(tournament: @tournament, kind: :fee, amount: 25)
    payment_create_charge_option(tournament: @other_tournament, kind: :buy_in)
    @other_rebuy = payment_create_charge_option(tournament: @other_tournament, kind: :rebuy)

    payment_create_registration(tournament: @tournament, user: @player)
    payment_create_registration(tournament: @other_tournament, user: @other_player)
  end

  def create_payment_for(user, status:, kind:)
    payment_create_registration_payment(
      tournament: @tournament,
      user: user,
      recorded_by: @owner,
      status: status,
      kind: kind
    )
  end

  def recharges_path(club_id: @club.id, tournament_id: @tournament.id)
    club_tournament_recharges_path(club_id, tournament_id)
  end
end
