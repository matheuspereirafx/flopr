class TournamentsController < ApplicationController
  before_action :set_member_club
  before_action :authorize_owner!, only: %i[new create edit update destroy]
  before_action :set_tournament, only: %i[edit update destroy]
  before_action :authorize_tournament_deletion!, only: :destroy

  def index
    @tournaments = @club.tournaments.order(starts_at: :asc)
  end
  def new
    @tournament = @club.tournaments.build

    Tournament::MINIMUM_BLIND_LEVELS.times do |index|
      @tournament.blind_levels.build(
        level: index + 1,
        duration_minutes: 15,
        ante: 0
      )
    end

    @tournament.blind_levels_count =
      Tournament::MINIMUM_BLIND_LEVELS
  end

  def create
    @tournament = @club.tournaments.build(tournament_params)
    @tournament.status = :draft

    if @tournament.save
      redirect_to new_club_tournament_charge_options_path(@club, @tournament),
                  notice: "Estrutura do torneio salva. Configure as regras financeiras."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @tournament.status = :draft

    if @tournament.update(tournament_params)
      redirect_to edit_club_tournament_charge_options_path(@club, @tournament),
                  notice: "Estrutura do torneio salva. Revise as regras financeiras."
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

    render plain: "Forbidden", status: :forbidden

  def set_tournament
    @tournament = @club.tournaments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end



  def authorize_tournament_deletion!
    return if performed?
    return if @current_membership.owner?

    render plain: "Forbidden", status: :forbidden
  end

  def tournament_params
    params.require(:tournament).permit(
      :name,
      :location,
      :max_players,
      :starts_at,
      :blind_levels_count,
      blind_levels_attributes: [
        :id,
        :level,
        :duration_minutes,
        :small_blind,
        :big_blind,
        :ante,
        :_destroy
      ]
    )
  end

  def authorize_owner!
    return if performed?
    return if @current_membership.owner?

    render plain: "Forbidden", status: :forbidden
  end
end
