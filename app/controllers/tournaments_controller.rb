class TournamentsController < ApplicationController
  before_action :set_member_club
  before_action :authorize_tournament_creation!, only: %i[new create]
  before_action :set_tournament, only: %i[edit update destroy]
  before_action :authorize_tournament_management!, only: %i[edit update]
  before_action :authorize_tournament_deletion!, only: :destroy

  def index
    @tournaments = @club.tournaments.order(starts_at: :asc)
  end

  def new
    @tournament = @club.tournaments.build
    5.times { |level| @tournament.blind_levels.build(level: level + 1, duration_minutes: 15) }
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

  def edit
  end

  def update
    if @tournament.update(tournament_params)
      redirect_to club_path(@club), notice: "Torneio atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tournament.destroy

    redirect_to club_path(@club),
                notice: "Torneio excluído com sucesso.",
                status: :see_other
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
    return if tournament_manager?

    render plain: "Forbidden", status: :forbidden
  end

  def set_tournament
    @tournament = @club.tournaments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def authorize_tournament_management!
    return if performed?
    return if tournament_manager?

    render plain: "Forbidden", status: :forbidden
  end

  def authorize_tournament_deletion!
    return if performed?
    return if @current_membership.owner?

    render plain: "Forbidden", status: :forbidden
  end

  def tournament_manager?
    @current_membership.owner? || @current_membership.admin?
  end

  def tournament_params
    params.require(:tournament).permit(
      :name,
      :location,
      :max_players,
      :starts_at,
      blind_levels_attributes: [
        :level,
        :duration_minutes,
        :small_blind,
        :big_blind,
        :ante
      ]
    )
  end
end
