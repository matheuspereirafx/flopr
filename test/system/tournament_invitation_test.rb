require "application_system_test_case"

class TournamentInvitationTest < ApplicationSystemTestCase
  def setup
    @club = Club.create!(name: "Poker House")
    @candidate = User.create!(
      name: "Candidate",
      email: "candidate@example.com",
      password: "password123"
    )
    @tournament = create_tournament
  end

  test "user applies through the invite link and confirms presence" do
    visit new_user_session_path
    fill_in "user_email", with: @candidate.email
    fill_in "user_password", with: "password123"
    click_button "Entrar"

    visit club_tournament_path(@club, @tournament, invite_token: @tournament.invite_token)
    assert_text @tournament.name
    assert_text "Convite para torneio"

    click_button "Confirmar presença"

    assert_text "Sua presença está confirmada."
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
