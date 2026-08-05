class TournamentsController < ApplicationController
  before_action :set_member_club
  before_action :authorize_tournament_creation!, only: %i[new create]

  def index
    @tournaments = @club.tournaments.order(starts_at: :asc)
  end

  def new
    @tournament = @club.tournaments.build
  end

  def create
    @tournament = @club.tournaments.build(tournament_params)
    @tournament.status = :posted

    if @tournament.save
      redirect_to club_path(@club), notice: "Torneio criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_member_club
    @club = current_user.clubs.find(params[:club_id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def authorize_tournament_creation!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end

  def tournament_params
    params.require(:tournament).permit(
      :name,
      :location,
      :max_players,
      :starts_at
    )
  end
end
