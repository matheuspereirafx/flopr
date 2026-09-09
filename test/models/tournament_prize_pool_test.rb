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

  test "requires a positive total amount" do
    prize_pool = @tournament.build_prize_pool(total_amount: 0)

    assert_not prize_pool.valid?
    assert_includes prize_pool.errors[:total_amount], "deve ser maior que 0"
  end

  test "stores the total amount with two decimal places" do
    prize_pool = @tournament.create_prize_pool!(
      total_amount: "1000.50",
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )

    assert_equal 1000.50.to_d, prize_pool.reload.total_amount
    assert_equal 1000.50.to_d, prize_pool.total_amount
  end

  test "requires prize percentages to total 100 percent" do
    prize_pool = @tournament.build_prize_pool(total_amount: 1000)
    prize_pool.prize_positions.build(position: 1, percentage: 30)
    prize_pool.prize_positions.build(position: 2, percentage: 25)

    assert_not prize_pool.valid?
    assert_includes prize_pool.errors[:base], "os percentuais devem totalizar 100%"
  end

  test "allows positions to be configured without registrations" do
    prize_pool = @tournament.build_prize_pool(total_amount: 1000)
    prize_pool.prize_positions.build(position: 1, percentage: 60)
    prize_pool.prize_positions.build(position: 2, percentage: 40)

    assert prize_pool.valid?
  end

  test "does not allow negative percentages" do
    prize_pool = @tournament.build_prize_pool(total_amount: 1000)
    prize_pool.prize_positions.build(position: 1, percentage: -10)
    prize_pool.prize_positions.build(position: 2, percentage: 110)

    assert_not prize_pool.valid?
  end

  test "does not allow duplicated positions" do
    prize_pool = @tournament.build_prize_pool(total_amount: 1000)
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
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )

    prize_pool.update!(total_amount: 1500)

    assert_equal 1500.to_d, prize_pool.reload.total_amount
  end

  private

  def create_tournament(attributes = {})
    defaults = {
      name: "Friday Poker Night #{SecureRandom.uuid}",
      location: "Poker House",
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
