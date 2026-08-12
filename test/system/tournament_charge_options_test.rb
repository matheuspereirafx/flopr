require "application_system_test_case"

class TournamentChargeOptionsTest < ApplicationSystemTestCase
  def setup
    @club = Club.create!(name: "Poker House")
    @owner = User.create!(
      name: "Owner",
      email: "owner@example.com",
      password: "password123"
    )
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    @tournament = create_draft_tournament
  end

  test "displays required and optional financial configuration" do
    sign_in_as_owner
    visit new_club_tournament_charge_options_path(@club, @tournament)

    assert_text "Configurações financeiras"
    assert_selector ".financial-panel--required"
    assert_selector "[data-kind='rebuy']:not(.financial-option--active)"
    assert_selector "[data-kind='rebuy'] [data-financial-options-target='toggle']", disabled: true
    assert_selector "[data-kind='double_rebuy'] [data-financial-options-target='toggle']"
    assert_selector "[data-kind='addon'] [data-financial-options-target='toggle']"
    assert_selector "[data-kind='fee'] [data-financial-options-target='toggle']"
  end

  private

  def sign_in_as_owner
    visit new_user_session_path
    fill_in "user_email", with: @owner.email
    fill_in "user_password", with: "password123"
    click_button "Entrar"
  end

  def create_draft_tournament
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
