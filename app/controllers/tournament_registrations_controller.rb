class TournamentRegistrationsController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :authorize_registrations_view!

  def index
    @registrations = @tournament.tournament_registrations.includes(:user)
    @current_registration = current_user.tournament_registrations.find_by(
      tournament: @tournament
    )
    @confirmed_registrations_count = @registrations.count(&:confirmed?)
    @pending_registrations_count = @registrations.count(&:pending?)
  end

  private

  def set_member_club
    @club = current_user.clubs.find(params[:club_id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def set_tournament
    return if performed?

    @tournament = @club.tournaments.find(params[:tournament_id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def authorize_registrations_view!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin? || @current_membership.dealer?
    return if @current_membership.player? && participating_player?

    render plain: "Forbidden", status: :forbidden
  end

  def participating_player?
    @tournament.tournament_registrations.exists?(user: current_user)
  end

end
