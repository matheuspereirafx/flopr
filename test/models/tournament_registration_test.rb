require "test_helper"

class TournamentRegistrationTest < ActiveSupport::TestCase
  test "belongs to a tournament and a user" do
    registration = TournamentRegistration.new

    assert_equal :belongs_to, registration.class.reflect_on_association(:tournament).macro
    assert_equal :belongs_to, registration.class.reflect_on_association(:user).macro
  end

  test "accepts pending and confirmed statuses" do
    tournament = create_tournament
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")

    pending = TournamentRegistration.create!(tournament: tournament, user: user, status: :pending)
    confirmed_user = User.create!(name: "Confirmed", email: "confirmed@example.com", password: "password123")
    confirmed = TournamentRegistration.create!(tournament: tournament, user: confirmed_user, status: :confirmed)

    assert_predicate pending, :pending?
    assert_predicate confirmed, :confirmed?
  end

  test "does not accept an unsupported status" do
    tournament = create_tournament
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")
    registration = TournamentRegistration.new(tournament: tournament, user: user)

    error = assert_raises ArgumentError do
      registration.status = :cancelled
    end

    assert_match /'cancelled' is not a valid status/, error.message
  end

  test "requires a status" do
    tournament = create_tournament
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")
    registration = TournamentRegistration.new(tournament: tournament, user: user, status: nil)

    assert_not registration.valid?
    assert_includes registration.errors[:status], "não pode ficar em branco"
  end

  test "does not allow the same user to register twice for a tournament" do
    tournament = create_tournament
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")
    TournamentRegistration.create!(tournament: tournament, user: user)

    duplicate = TournamentRegistration.new(tournament: tournament, user: user)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "já possui uma inscrição neste torneio"
  end

  test "persists a status change from pending to confirmed" do
    tournament = create_tournament
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")
    registration = TournamentRegistration.create!(tournament: tournament, user: user, status: :pending)

    registration.update!(status: :confirmed)

    assert_predicate registration.reload, :confirmed?
  end

  private

  def create_tournament
    club = Club.create!(name: "Poker House")
    tournament = club.tournaments.build(
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
