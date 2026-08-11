require "application_system_test_case"

class TournamentBlindStructureTest < ApplicationSystemTestCase
  def setup
    @club = Club.create!(name: "Poker House")
    @owner = User.create!(
      name: "Owner",
      email: "owner@example.com",
      password: "password123"
    )
    ClubMembership.create!(user: @owner, club: @club, role: :owner)

    sign_in_as_owner
    visit new_club_tournament_path(@club)
  end

  test "starts with five levels and prevents removal below the minimum" do
    assert_equal 5, all("tbody[data-blind-structure-target='body'] tr").count
    assert all("[data-blind-structure-target='removeButton']").all?(&:disabled?)
  end

  test "adds levels and synchronizes selected quantity" do
    click_button "Adicionar nível"

    assert_equal 6, all("tbody[data-blind-structure-target='body'] tr").count
    assert_equal "6", find("#tournament_blind_levels_count").value
  end

  test "changes the selected quantity by adding and removing final levels" do
    count_input = find("#tournament_blind_levels_count")
    count_input.set(7)
    count_input.send_keys(:tab)

    assert_equal 7, visible_level_rows.count

    last("[data-blind-structure-target='smallBlind']").set(700)
    count_input.set(5)
    count_input.send_keys(:tab)

    assert_equal 5, visible_level_rows.count
    assert_equal "5", count_input.value
  end

  test "updates every duration immediately" do
    select "20 minutos", from: "level-duration"

    assert all("[data-blind-structure-target='durationLabel']").all? do |label|
      label.text == "20 min"
    end
  end

  test "new levels use the selected duration" do
    select "20 minutos", from: "level-duration"

    click_button "Adicionar nível"

    assert_equal "20 min", all("[data-blind-structure-target='durationLabel']").last.text
  end

  test "suggests big blind from small blind" do
    small_blind = first("[data-blind-structure-target='smallBlind']")
    small_blind.set(100)

    assert_equal "200", first("[data-blind-structure-target='bigBlind']").value
  end

  test "removes a configured extra level and renumbers rows" do
    click_button "Adicionar nível"
    last("[data-blind-structure-target='smallBlind']").set(100)

    all("[data-blind-structure-target='removeButton']").last.click

    assert_equal 5, visible_level_rows.count
    assert_equal %w[1 2 3 4 5], all("[data-blind-structure-target='levelLabel']").map(&:text)
  end

  private

  def sign_in_as_owner
    visit new_user_session_path
    fill_in "user_email", with: @owner.email
    fill_in "user_password", with: "password123"
    click_button "Entrar"
  end

  def visible_level_rows
    all("tbody[data-blind-structure-target='body'] tr").reject(&:hidden?)
  end
end
