class PlayerTournamentsController < ApplicationController
  def index
    member_club_ids = current_user.club_memberships.select(:club_id)

    @upcoming_tournaments = Tournament
                            .where(club_id: member_club_ids)
                            .where("starts_at >= ?", Time.current)
                            .includes(:club, :charge_options)
                            .order(starts_at: :asc)

    @my_tournaments = current_user.tournament_registrations
                                  .includes(tournament: %i[club charge_options])
                                  .map(&:tournament)
                                  .sort_by(&:starts_at)

    tournaments = @upcoming_tournaments.to_a + @my_tournaments
    @confirmed_registrations_by_tournament = TournamentRegistration
                                             .confirmed
                                             .where(tournament_id: tournaments.map(&:id))
                                             .group(:tournament_id)
                                             .count
    @current_memberships_by_club_id = current_user.club_memberships
                                                     .index_by(&:club_id)
  end
end
