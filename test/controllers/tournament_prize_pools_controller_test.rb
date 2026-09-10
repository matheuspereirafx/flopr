require "test_helper"

class TournamentPrizePoolsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @club = Club.create!(name: "Poker House")
    @other_club = Club.create!(name: "Other Poker House")
    @owner = create_user("owner@example.com")
    @admin = create_user("admin@example.com")
    @dealer = create_user("dealer@example.com")
    @player = create_user("player@example.com")
    @outsider = create_user("outsider@example.com")

    create_membership(@owner, @club, :owner)
    create_membership(@admin, @club, :admin)
    create_membership(@dealer, @club, :dealer)
    create_membership(@player, @club, :player)
    create_membership(@outsider, @other_club, :owner)
    @tournament = create_tournament(@club)
  end

  test "owner and admin can access the prize configuration" do
    [@owner, @admin].each do |user|
      sign_in user
      get new_club_tournament_prize_pool_path(@club, @tournament)

      assert_response :success
      assert_select "input[name='prize_pool[total_amount]']", count: 1
      assert_select "input[name^='prize_pool[prize_positions_attributes]']", minimum: 1
      sign_out user
    end
  end

  test "dealer and player cannot access the prize configuration" do
    [@dealer, @player].each do |user|
      sign_in user
      get new_club_tournament_prize_pool_path(@club, @tournament)

      assert_response :forbidden
      sign_out user
    end
  end

  test "outsider cannot access a prize configuration from another club" do
    sign_in @outsider

    get new_club_tournament_prize_pool_path(@club, @tournament)

    assert_response :not_found
  end

  test "unauthenticated user is redirected to sign in" do
    get new_club_tournament_prize_pool_path(@club, @tournament)

    assert_redirected_to new_user_session_path
  end

  test "owner creates a prize pool with positions" do
    sign_in @owner

    assert_difference "TournamentPrizePool.count", 1 do
      assert_difference "TournamentPrizePosition.count", 2 do
        post club_tournament_prize_pool_path(@club, @tournament),
             params: prize_pool_payload
      end
    end

    prize_pool = @tournament.reload.prize_pool
    assert_equal 1000.to_d, prize_pool.total_amount
    assert_equal [1, 2], prize_pool.prize_positions.order(:position).pluck(:position)
    assert_redirected_to club_tournament_path(@club, @tournament)
  end

  test "cannot save percentages that do not total 100 percent" do
    sign_in @owner

    assert_no_difference "TournamentPrizePool.count" do
      post club_tournament_prize_pool_path(@club, @tournament),
           params: prize_pool_payload(percentages: [30, 25])
    end

    assert_response :unprocessable_entity
  end

  test "owner can edit the prize pool after publication" do
    prize_pool = @tournament.create_prize_pool!(
      total_amount: 1000,
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )
    @tournament.charge_options.create!(kind: :buy_in, active: true, amount: 50, chip_amount: 10_000)
    @tournament.update!(status: :posted)
    sign_in @owner

    patch club_tournament_prize_pool_path(@club, @tournament),
          params: prize_pool_payload(
            total_amount: "1500.00",
            percentages: [60, 40],
            first_position_id: prize_pool.prize_positions.first.id
          )

    assert_redirected_to club_tournament_path(@club, @tournament)
    assert_equal 1500.to_d, prize_pool.reload.total_amount
  end

  test "financial configuration leads to prize pool edit when it already exists" do
    prize_pool = @tournament.create_prize_pool!(
      total_amount: 1000,
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )
    sign_in @owner

    post club_tournament_charge_options_path(@club, @tournament),
         params: financial_configuration_payload

    assert_redirected_to edit_club_tournament_prize_pool_path(@club, @tournament)
    assert_equal prize_pool.id, @tournament.reload.prize_pool.id
  end

  private

  def prize_pool_payload(total_amount: "1000.00", percentages: [60, 40], first_position_id: nil)
    {
      prize_pool: {
        total_amount: total_amount,
        prize_positions_attributes: {
          "0" => { id: first_position_id, position: 1, percentage: percentages[0] },
          "1" => { position: 2, percentage: percentages[1] }
        }
      }
    }
  end

  def financial_configuration_payload
    {
      financial_configuration: {
        period_end_level_id: nil,
        charge_options: {
          buy_in: { active: "1", amount: "50.00", chip_amount: "10000" },
          rebuy: { active: "0", amount: "", chip_amount: "" },
          double_rebuy: { active: "0", amount: "", chip_amount: "" },
          addon: { active: "0", amount: "", chip_amount: "" },
          fee: { active: "0", amount: "", chip_amount: "" }
        }
      }
    }
  end

  def create_user(email)
    User.create!(email: email, password: "password123", name: email.split("@").first,
                username: email.split("@").first)
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def create_tournament(club)
    tournament = club.tournaments.build(
      name: "Friday Poker Night #{SecureRandom.uuid}",
      location: "Poker House",
      google_place_id: "ChIJtestplace",
      max_players: 20,
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
