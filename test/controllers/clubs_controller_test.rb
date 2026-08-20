require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @owner = User.create!(
      email: "owner@example.com",
      password: "password123",
      name: "Owner"
    )
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
  end

  test "shows the configured buy in amount in the tournament card" do
    tournament = create_tournament
    tournament.charge_options.create!(
      kind: :buy_in,
      active: true,
      amount: 125.5,
      chip_amount: 10_000
    )

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select ".tournament-card__information-value--highlight", "R$ 125,50"
    assert_not_select ".tournament-card__information-value--highlight", "R$ 250"
  end

  test "shows buy in as pending when the tournament has no financial configuration" do
    create_tournament

    sign_in @owner
    get club_path(@club)

    assert_response :success
    assert_select ".tournament-card__information-value--highlight", "A definir"
  end

  test "shows confirmed registrations and tournament capacity in the tournament card" do
    tournament = create_tournament
    confirmed_player = User.create!(
      email: "confirmed@example.com",
      password: "password123",
      name: "Confirmed"
    )
    pending_player = User.create!(
      email: "pending@example.com",
      password: "password123",
      name: "Pending"
    )
    TournamentRegistration.create!(
      tournament: tournament,
      user: confirmed_player,
      status: :confirmed
    )
    TournamentRegistration.create!(
      tournament: tournament,
      user: pending_player,
      status: :pending
    )

    sign_in @owner
    get club_path(@club)

    assert_select ".tournament-card__players-value strong", "1"
    assert_select ".tournament-card__players-value span", "/ 24"
  end

  private

  def create_tournament
    tournament = @club.tournaments.build(
      name: "Friday Poker Night",
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft
    )

    5.times do |index|
      level = index + 1
      tournament.blind_levels.build(
        level: level,
        duration_minutes: 15,
        small_blind: level * 100,
        big_blind: level * 200,
        ante: 0
      )
    end

    tournament.save!
    tournament
  end
end
