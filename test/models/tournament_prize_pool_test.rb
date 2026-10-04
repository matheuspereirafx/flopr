require "test_helper"

class TournamentPrizePoolTest < ActiveSupport::TestCase
  def setup
    @club = Club.create!(name: "Poker House")
    @tournament = create_tournament
  end

  test "belongs to a tournament" do
    assert_equal :belongs_to,
                 TournamentPrizePool.reflect_on_association(:tournament).macro
  end

  test "has prize positions" do
    assert_equal :has_many,
                 TournamentPrizePool.reflect_on_association(:prize_positions).macro
  end

  test "defaults rake percentage to zero" do
    prize_pool = @tournament.build_prize_pool(rake_percentage: 0)
    prize_pool.prize_positions.build(position: 1, percentage: 100)

    assert prize_pool.valid?
    assert_equal 0, prize_pool.rake_percentage
  end

  test "accepts rake percentages from zero to one hundred" do
    [0, 37, 100].each do |rake_percentage|
      prize_pool = @tournament.build_prize_pool(rake_percentage: rake_percentage)
      prize_pool.prize_positions.build(position: 1, percentage: 100)

      assert prize_pool.valid?
    end
  end

  test "rejects negative, greater than one hundred, and non-integer rake percentages" do
    [-1, 101, "12.5", "12,5"].each do |rake_percentage|
      prize_pool = @tournament.build_prize_pool(rake_percentage: rake_percentage)

      assert_not prize_pool.valid?
      assert prize_pool.errors[:rake_percentage].any?
    end
  end

  test "stores the existing total amount when provided" do
    prize_pool = @tournament.create_prize_pool!(
      total_amount: "1000.50",
      rake_percentage: 10,
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )

    assert_equal 1000.50.to_d, prize_pool.reload.total_amount
    assert_equal 1000.50.to_d, prize_pool.total_amount
  end

  test "calculates the net prize pool from eligible paid payments" do
    owner = User.create!(email: "prize-owner@example.com", username: "prize_owner", password: "password123", name: "Owner")
    player = User.create!(email: "prize-player@example.com", username: "prize_player", password: "password123", name: "Player")
    registration = @tournament.tournament_registrations.create!(user: player, status: :confirmed)
    @tournament.charge_options.create!(kind: :buy_in, amount: 100, chip_amount: 10_000)
    @tournament.charge_options.create!(kind: :rebuy, amount: 50, chip_amount: 5_000)
    @tournament.charge_options.create!(kind: :double_rebuy, amount: 90, chip_amount: 9_000)
    @tournament.charge_options.create!(kind: :addon, amount: 25, chip_amount: 2_500)
    @tournament.charge_options.create!(kind: :fee, amount: 10, chip_amount: 1_000)

    create_payment(registration, :buy_in, 100, owner, :paid)
    create_payment(registration, :rebuy, 50, owner, :paid)
    create_payment(registration, :double_rebuy, 90, owner, :paid)
    create_payment(registration, :addon, 25, owner, :paid)
    create_payment(registration, :fee, 10, owner, :paid)
    create_payment(registration, :buy_in, 100, owner, :pending)

    prize_pool = @tournament.create_prize_pool!(
      rake_percentage: 10,
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )

    assert_equal 265.to_d, prize_pool.gross_amount
    assert_equal 26.5.to_d, prize_pool.rake_amount
    assert_equal 238.5.to_d, prize_pool.net_amount
  end

  test "requires prize percentages to total 100 percent" do
    prize_pool = @tournament.build_prize_pool(rake_percentage: 0)
    prize_pool.prize_positions.build(position: 1, percentage: 30)
    prize_pool.prize_positions.build(position: 2, percentage: 25)

    assert_not prize_pool.valid?
    assert_includes prize_pool.errors[:base], "os percentuais devem totalizar 100%"
  end

  test "allows positions to be configured without registrations" do
    prize_pool = @tournament.build_prize_pool(rake_percentage: 0)
    prize_pool.prize_positions.build(position: 1, percentage: 60)
    prize_pool.prize_positions.build(position: 2, percentage: 40)

    assert prize_pool.valid?
  end

  test "does not allow negative percentages" do
    prize_pool = @tournament.build_prize_pool(rake_percentage: 0)
    prize_pool.prize_positions.build(position: 1, percentage: -10)
    prize_pool.prize_positions.build(position: 2, percentage: 110)

    assert_not prize_pool.valid?
  end

  test "does not allow duplicated positions" do
    prize_pool = @tournament.build_prize_pool(rake_percentage: 0)
    prize_pool.prize_positions.build(position: 1, percentage: 50)
    prize_pool.prize_positions.build(position: 1, percentage: 50)

    assert_not prize_pool.valid?
  end

  test "can be edited after tournament publication" do
    tournament = create_tournament
    tournament.charge_options.create!(
      kind: :buy_in,
      active: true,
      amount: 50,
      chip_amount: 10_000
    )
    tournament.update!(status: :posted)
    prize_pool = tournament.create_prize_pool!(
      total_amount: 1000,
      rake_percentage: 0,
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )

    prize_pool.update!(rake_percentage: 15)

    assert_equal 15, prize_pool.reload.rake_percentage
  end

  private

  def create_payment(registration, kind, amount, recorded_by, status)
    RegistrationPayment.create!(
      tournament_registration: registration,
      tournament_charge_option: @tournament.charge_options.find_by!(kind: kind),
      amount: amount,
      status: status,
      provider: "manual",
      payment_method: :manual,
      recorded_by: recorded_by
    )
  end

  def create_tournament(attributes = {})
    defaults = {
      name: "Friday Poker Night #{SecureRandom.uuid}",
      location: "Poker House",
      google_place_id: "ChIJtestplace",
      max_players: 20,
      starts_at: 2.days.from_now,
      status: :draft
    }
    tournament = @club.tournaments.build(defaults.merge(attributes))

    5.times do |index|
      tournament.blind_levels.build(
        level: index + 1,
        duration_minutes: 15,
        small_blind: (index + 1) * 100,
        big_blind: (index + 1) * 200,
        ante: 0
      )
    end

    tournament.save!
    tournament
  end
end
