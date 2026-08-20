class TournamentInviteLinksController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :authorize_invite_link_management!

  def show
    @invite_url = club_tournament_url(
      @club,
      @tournament,
      invite_token: @tournament.invite_token
    )
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

  def authorize_invite_link_management!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end
end
