require "test_helper"

class TournamentFinancialsChannelTest < ActionCable::Channel::TestCase
  include ActionCable::TestHelper

  test "owner and admin can subscribe to tournament financials" do
    [@owner, @admin].each do |user|
      stub_connection current_user: user
      subscribe club_id: @club.id, tournament_id: @tournament.id

      assert subscription.confirmed?
      unsubscribe
    end
  end

  test "dealer and player cannot subscribe to tournament financials" do
    [@dealer, @player].each do |user|
      stub_connection current_user: user
      subscribe club_id: @club.id, tournament_id: @tournament.id

      assert subscription.rejected?
    end
  end

  test "broadcasts the current net prize pool" do
    prize_pool = @tournament.create_prize_pool!(
      rake_percentage: 10,
      prize_positions_attributes: { "0" => { position: 1, percentage: 100 } }
    )

    assert_broadcast_on("tournament_financials_#{@tournament.id}", net_amount: "0.0") do
      TournamentFinancialsChannel.broadcast_summary(@tournament)
    end
  end

  private

  def setup
    @club = Club.create!(name: "Poker House")
    @tournament = create_tournament
    @owner = create_user("owner-financials@example.com")
    @admin = create_user("admin-financials@example.com")
    @dealer = create_user("dealer-financials@example.com")
    @player = create_user("player-financials@example.com")

    create_membership(@owner, @club, :owner)
    create_membership(@admin, @club, :admin)
    create_membership(@dealer, @club, :dealer)
    create_membership(@player, @club, :player)
  end

  def create_tournament
    tournament = @club.tournaments.build(
      name: "Financials #{SecureRandom.uuid}",
      location: "Poker House",
      google_place_id: "ChIJtestplace",
      max_players: 20,
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

  def create_user(email)
    username = email.split("@").first.tr("-", "_")
    User.create!(email: email, username: username, password: "password123", name: username)
  end

  def create_membership(user, club, role)
    ClubMembership.create!(user: user, club: club, role: role)
  end
end
