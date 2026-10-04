class TournamentFinancialsChannel < ApplicationCable::Channel
  def subscribed
    club = current_user.clubs.find(params[:club_id])
    tournament = club.tournaments.find(params[:tournament_id])
    membership = club.club_memberships.find_by!(user: current_user)
    reject unless membership.owner? || membership.admin?

    stream_from self.class.stream_name(tournament)
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def self.broadcast_summary(tournament)
    prize_pool = tournament.prize_pool
    return unless prize_pool

    ActionCable.server.broadcast(
      stream_name(tournament),
      { net_amount: prize_pool.net_amount.to_s }
    )
  end

  def self.stream_name(tournament)
    "tournament_financials_#{tournament.id}"
  end
end
