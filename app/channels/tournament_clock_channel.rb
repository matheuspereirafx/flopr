class TournamentClockChannel < ApplicationCable::Channel
  def subscribed
    club = current_user.clubs.find(params[:club_id])
    tournament = club.tournaments.find(params[:tournament_id])

    stream_from stream_name(tournament)
  rescue ActiveRecord::RecordNotFound
    reject
  end

  private

  def stream_name(tournament)
    "tournament_clock_#{tournament.id}"
  end
end
