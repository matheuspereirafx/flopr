require "test_helper"

class TournamentClockChannelTest < ActionCable::Channel::TestCase
  def setup
    @club = create_club
    @tournament = create_tournament(club: @club)
    @member = create_user(email: "clock-member@example.com")
    @outsider = create_user(email: "clock-outsider@example.com")
    create_membership(user: @member, club: @club, role: :player)
  end

  test "club member subscribes to the tournament clock" do
    stub_connection(current_user: @member)

    subscribe club_id: @club.id, tournament_id: @tournament.id

    assert subscription.confirmed?
    assert_has_stream "tournament_clock_#{@tournament.id}"
  end

  test "user outside the club cannot subscribe" do
    stub_connection(current_user: @outsider)

    subscribe club_id: @club.id, tournament_id: @tournament.id

    assert subscription.rejected?
    assert_no_streams
  end
end
