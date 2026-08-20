require "application_system_test_case"

class TournamentOverviewTest < ApplicationSystemTestCase
  def setup
    @club = Club.create!(name: "Poker House")
    @player = User.create!(
      name: "Player",
      email: "player@example.com",
      password: "password123"
    )
    ClubMembership.create!(user: @player, club: @club, role: :player)
    @tournament = create_tournament
  end

  test "member views the tournament overview" do
    sign_in_as_player
    visit club_tournament_path(@club, @tournament)

    assert_text @tournament.name
    assert_text @tournament.location
    assert_text "Detalhes"
    assert_text "Buy-in"
    assert_text "Premiação disponível após a finalização do torneio."
    assert_text "Confirmados"
    assert_text "Pendentes"
    assert_text "Vagas disponíveis"
    assert_no_text "Abrir relógio"
  end

  private

  def sign_in_as_player
    visit new_user_session_path
    fill_in "user_email", with: @player.email
    fill_in "user_password", with: "password123"
    click_button "Entrar"
  end

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
