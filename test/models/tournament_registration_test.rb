require "test_helper"

class TournamentRegistrationTest < ActiveSupport::TestCase
  test "does not allow the same user to register twice for a tournament" do
    tournament = create_tournament
    user = User.create!(name: "Player", email: "player@example.com", password: "password123")
    TournamentRegistration.create!(tournament: tournament, user: user)

    duplicate = TournamentRegistration.new(tournament: tournament, user: user)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "já possui uma inscrição neste torneio"
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
