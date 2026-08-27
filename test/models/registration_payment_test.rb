require "test_helper"

class RegistrationPaymentTest < ActiveSupport::TestCase
  test "requires the production model and payment table" do
    assert defined?(RegistrationPayment),
           "RegistrationPayment production model has not been implemented"
    assert RegistrationPayment.table_exists?,
           "registration_payments production table has not been implemented"
  end

  test "belongs to a tournament registration, charge option, and responsible user" do
    payment = build_payment

    assert_equal TournamentRegistration, payment.class.reflect_on_association(:tournament_registration).klass
    assert_equal TournamentChargeOption, payment.class.reflect_on_association(:tournament_charge_option).klass
    assert_equal User, payment.class.reflect_on_association(:recorded_by).klass
  end

  test "accepts every documented payment status" do
    assert_equal %w[pending paid failed cancelled refunded].sort,
                 RegistrationPayment.statuses.keys.sort
  end

  test "rejects an invalid status" do
    error = assert_raises(ArgumentError) do
      build_payment(status: "unknown")
    end

    assert_equal "'unknown' is not a valid status", error.message
  end

  test "accepts the supported payment methods" do
    assert_equal %w[card manual pix], RegistrationPayment.payment_methods.keys.sort
  end

  test "rejects an unsupported payment method" do
    payment = build_payment
    payment.payment_method = "bank_transfer"

    assert_not payment.valid?
    assert_includes payment.errors[:payment_method], "não está incluído na lista"
  end

  test "rejects a negative amount" do
    payment = build_payment(amount: -1)

    assert_not payment.valid?
  end

  test "rejects a payment whose registration and charge option belong to different tournaments" do
    other_tournament = payment_create_tournament(club: @club, name: "Other Tournament")
    other_option = payment_create_charge_option(tournament: other_tournament)
    payment = build_payment(tournament_charge_option: other_option)

    assert_not payment.valid?
  end

  test "keeps cancelled payments persisted and identifiable" do
    payment = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @owner,
      status: :cancelled
    )

    assert_predicate payment, :cancelled?
    assert RegistrationPayment.exists?(payment.id)
  end

  test "calculates totals according to the approved financial policy" do
    payment_create_registration_payment(tournament: @tournament, user: @player, recorded_by: @owner, status: :paid, amount: 50)
    payment_create_registration_payment(tournament: @tournament, user: @admin, recorded_by: @owner, status: :pending, amount: 30)

    assert_equal 50.to_d, @tournament.registration_payments.paid.sum(:amount)
  end

  test "stores the Asaas payment identifier and payment approval time" do
    paid_at = Time.zone.local(2026, 8, 27, 20, 33, 10)
    payment = build_payment
    payment.provider_payment_id = "pay_sandbox_123"
    payment.paid_at = paid_at

    assert payment.save
    assert_equal "pay_sandbox_123", payment.reload.provider_payment_id
    assert_equal paid_at, payment.reload.paid_at
  end

  test "does not allow a duplicate Asaas payment identifier" do
    first = payment_create_registration_payment(
      tournament: @tournament,
      user: @player,
      recorded_by: @owner,
      status: :pending
    )
    first.update!(provider_payment_id: "pay_existing")
    duplicate = build_payment
    duplicate.provider_payment_id = first.provider_payment_id

    assert_not duplicate.valid?
  end

  private

  def setup
    @club = payment_create_club
    @owner = payment_create_user("owner-payment@example.com")
    @admin = payment_create_user("admin-payment@example.com")
    @player = payment_create_user("player-payment@example.com")

    payment_create_membership(user: @owner, club: @club, role: :owner)
    payment_create_membership(user: @admin, club: @club, role: :admin)
    payment_create_membership(user: @player, club: @club, role: :player)

    @tournament = payment_create_tournament(club: @club)
    payment_create_charge_option(tournament: @tournament)
    payment_create_registration(tournament: @tournament, user: @player)
    payment_create_registration(tournament: @tournament, user: @admin)
  end

  def build_payment(status: :paid, amount: 50, tournament_charge_option: @charge_option)
    @charge_option ||= @tournament.charge_options.find_by!(kind: :buy_in)
    RegistrationPayment.new(
      tournament_registration: @tournament.tournament_registrations.find_by!(user: @player),
      tournament_charge_option: tournament_charge_option || @charge_option,
      amount: amount,
      status: status,
      provider: "gateway",
      payment_method: "pix",
      recorded_by: @owner
    )
  end
end
