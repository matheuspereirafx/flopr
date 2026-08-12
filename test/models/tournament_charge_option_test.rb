require "test_helper"

class TournamentChargeOptionTest < ActiveSupport::TestCase
  def setup
    @club = Club.create!(name: "Poker House")
    @tournament = create_tournament(@club)
  end

  test "active option requires non-negative amount and chip amount" do
    option = @tournament.charge_options.build(
      kind: :buy_in,
      active: true,
      amount: -1,
      chip_amount: -1
    )

    assert_not option.valid?
    assert_includes option.errors[:amount], "deve ser maior ou igual a 0"
    assert_includes option.errors[:chip_amount], "deve ser maior ou igual a 0"
  end

  test "inactive option does not require financial fields" do
    option = @tournament.charge_options.build(kind: :addon, active: false)

    assert option.valid?
  end

  test "inactive option still rejects negative values" do
    option = @tournament.charge_options.build(
      kind: :addon,
      active: false,
      amount: -1,
      chip_amount: -1
    )

    assert_not option.valid?
    assert_includes option.errors[:amount], "deve ser maior ou igual a 0"
    assert_includes option.errors[:chip_amount], "deve ser maior ou igual a 0"
  end

  test "active fee is identified by kind and does not require a name" do
    option = @tournament.charge_options.build(
      kind: :fee,
      active: true,
      amount: 10,
      chip_amount: 0
    )

    assert option.valid?
    assert_not option.respond_to?(:name)
  end

  test "buy in cannot have a blind availability period" do
    option = @tournament.charge_options.build(
      kind: :buy_in,
      active: true,
      amount: 50,
      chip_amount: 10_000,
      available_from_level: @tournament.blind_levels.first
    )

    assert_not option.valid?
    assert_includes option.errors[:base], "buy-in não possui período de disponibilidade"
  end

  private

  def create_tournament(club)
    tournament = club.tournaments.build(
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft
    )

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
