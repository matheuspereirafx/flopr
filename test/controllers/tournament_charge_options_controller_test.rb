require "test_helper"

class TournamentChargeOptionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @other_club = Club.create!(name: "Other Poker House")
    @owner = create_user("owner@example.com")
    @admin = create_user("admin@example.com")
    @outsider = create_user("outsider@example.com")
    ClubMembership.create!(user: @owner, club: @club, role: :owner)
    ClubMembership.create!(user: @admin, club: @club, role: :admin)
    ClubMembership.create!(user: @outsider, club: @other_club, role: :owner)
    @tournament = create_draft_tournament
  end

  test "owner views financial configuration" do
    sign_in @owner

    get new_club_tournament_charge_options_path(@club, @tournament)

    assert_response :success
    assert_select ".financial-form__step", "Etapa 2 de 2"
    assert_select "h1", "Configurações financeiras"
    assert_select ".form-grid.financial-form__grid > .panel", count: 2
    assert_select ".financial-panel--required .panel__title", "Buy-in obrigatório"
    assert_select ".financial-panel--optional .panel__title", "Recargas e opções adicionais"
    assert_select ".financial-options-list [data-kind]", count: 4
    assert_select ".financial-switch__control", count: 4
    assert_select "[data-kind='rebuy'] input[data-financial-options-target='toggle'][disabled]", count: 1
    assert_select "[data-kind='double_rebuy'] input[data-financial-options-target='toggle'][disabled]", count: 1
    assert_select "[data-kind='addon'] input[data-financial-options-target='toggle'][disabled]", count: 1
    assert_select "[data-kind='fee'] input[data-financial-options-target='toggle'][disabled]", count: 1
    assert_select "input[name='financial_configuration[charge_options][buy_in][amount]']", count: 1
  end

  test "owner publishes tournament with buy in and no recharge period" do
    sign_in @owner

    post club_tournament_charge_options_path(@club, @tournament),
         params: financial_configuration_payload(nil, optional_options: false)

    assert_redirected_to club_path(@club)
    assert_equal "posted", @tournament.reload.status
    assert @tournament.charge_options.find_by!(kind: :buy_in).active?
    assert_not @tournament.charge_options.find_by!(kind: :rebuy).active?
    assert_not @tournament.charge_options.find_by!(kind: :double_rebuy).active?
    assert_not @tournament.charge_options.find_by!(kind: :addon).active?
    assert_not @tournament.charge_options.find_by!(kind: :fee).active?
  end

  test "active rebuy requires a selected final level" do
    sign_in @owner

    post club_tournament_charge_options_path(@club, @tournament),
         params: financial_configuration_payload(nil)

    assert_response :unprocessable_entity
    assert_equal "draft", @tournament.reload.status
  end

  test "owner saves buy in rebuy and the shared availability period" do
    sign_in @owner
    period_end = @tournament.blind_levels.third

    post club_tournament_charge_options_path(@club, @tournament),
         params: financial_configuration_payload(period_end.id)

    assert_redirected_to club_path(@club)
    assert_equal "posted", @tournament.reload.status

    buy_in = @tournament.charge_options.find_by!(kind: :buy_in)
    rebuy = @tournament.charge_options.find_by!(kind: :rebuy)
    addon = @tournament.charge_options.find_by!(kind: :addon)
    fee = @tournament.charge_options.find_by!(kind: :fee)

    assert_equal 50.to_d, buy_in.amount
    assert_equal 10_000, buy_in.chip_amount
    assert_equal @tournament.blind_levels.first, rebuy.available_from_level
    assert_equal period_end, rebuy.available_until_level
    assert_equal period_end, addon.available_from_level
    assert_nil addon.available_until_level
    assert_equal period_end, fee.available_until_level
  end

  test "owner cannot save with missing buy in values" do
    sign_in @owner
    payload = financial_configuration_payload(@tournament.blind_levels.second.id)
    payload[:financial_configuration][:charge_options][:buy_in][:amount] = ""

    post club_tournament_charge_options_path(@club, @tournament), params: payload

    assert_response :unprocessable_entity
    assert_equal "draft", @tournament.reload.status
    assert_includes response.body, "não pode ficar em branco"
  end

  test "admin and outsider cannot access the financial configuration" do
    sign_in @admin
    get new_club_tournament_charge_options_path(@club, @tournament)
    assert_response :forbidden

    sign_out @admin
    sign_in @outsider
    get new_club_tournament_charge_options_path(@club, @tournament)
    assert_response :not_found
  end

  test "unauthenticated user is redirected to sign in" do
    get new_club_tournament_charge_options_path(@club, @tournament)

    assert_redirected_to new_user_session_path
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", name: email.split("@").first)
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

  def financial_configuration_payload(period_end_level_id, optional_options: true)
    {
      financial_configuration: {
        period_end_level_id: period_end_level_id,
        charge_options: {
          buy_in: { active: "1", amount: "50.00", chip_amount: "10000" },
          rebuy: {
            active: optional_options ? "1" : "0",
            amount: optional_options ? "30.00" : "",
            chip_amount: optional_options ? "5000" : ""
          },
          double_rebuy: { active: "0", amount: "", chip_amount: "" },
          addon: {
            active: optional_options ? "1" : "0",
            amount: optional_options ? "20.00" : "",
            chip_amount: optional_options ? "3000" : ""
          },
          fee: {
            active: optional_options ? "1" : "0",
            amount: optional_options ? "5.00" : "",
            chip_amount: optional_options ? "0" : ""
          }
        }
      }
    }
  end
end
