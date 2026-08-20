class TournamentsController < ApplicationController
  before_action :set_member_club
  before_action :authorize_owner!, only: %i[new create edit update destroy]
  before_action :set_tournament, only: %i[show edit update destroy]
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

  def show
    @buy_in = @tournament.charge_options.find do |option|
      option.buy_in? && option.active?
    end
    @invite_token_access = invitation_show_request?
    @invite_registration = current_user.tournament_registrations.find_by(
      tournament: @tournament
    )
    @invite_url = club_tournament_url(
      @club,
      @tournament,
      invite_token: @tournament.invite_token
    )
  end

  def create
    @tournament = @club.tournaments.build(tournament_params)
    @tournament.status = :draft

    if create_tournament_with_clock_state
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
    return set_invited_tournament if invitation_show_request?

    render plain: "Not found", status: :not_found
  end

  def set_tournament
    return if @tournament.present?

    @tournament = @club.tournaments.find(params[:id])
    return unless invitation_show_request?
    return if @tournament.invite_token == params[:invite_token] && @tournament.invite_link_valid?

    raise ActiveRecord::RecordNotFound
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

  def create_tournament_with_clock_state
    ApplicationRecord.transaction do
      @tournament.save!
      TournamentClockState.create_initial_for!(@tournament)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def authorize_owner!
    return if performed?
    return if @current_membership.owner?

    render plain: "Forbidden", status: :forbidden
  end

  def invitation_show_request?
    action_name == "show" && params[:invite_token].present?
  end

  def set_invited_tournament
    @tournament = Tournament.find_by!(invite_token: params[:invite_token])
    raise ActiveRecord::RecordNotFound unless @tournament.club_id == params[:club_id].to_i
    raise ActiveRecord::RecordNotFound unless @tournament.id == params[:id].to_i
    raise ActiveRecord::RecordNotFound unless @tournament.invite_link_valid?

    @club = @tournament.club
    @current_membership = @club.club_memberships.find_by(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
