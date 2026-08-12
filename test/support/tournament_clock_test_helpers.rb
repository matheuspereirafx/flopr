module TournamentClockTestHelpers
  def create_user(email: "user-#{SecureRandom.uuid}@example.com")
    User.create!(
      email: email,
      password: "password123",
      name: email.split("@").first
    )
  end

  def create_club(name: "Poker House #{SecureRandom.uuid}")
    Club.create!(name: name)
  end

  def create_membership(user:, club:, role: :player)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_tournament(club:, name: "Friday Poker Night #{SecureRandom.uuid}")
    tournament = Tournament.create!(
      club: club,
      name: name,
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft,
      blind_levels_attributes: blind_levels_attributes
    )

    tournament
  end

  def blind_levels_attributes(count: 5, duration_minutes: 15)
    count.times.map do |index|
      level = index + 1

      {
        level: level,
        duration_minutes: duration_minutes,
        small_blind: level * 100,
        big_blind: level * 200,
        ante: 0
      }
    end
  end
end

class ActiveSupport::TestCase
  include TournamentClockTestHelpers
end
