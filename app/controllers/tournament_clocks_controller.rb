class TournamentClocksController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :set_clock_state
  before_action :authorize_clock_operation!, only: :start
  before_action :authorize_clock_pause!, only: :pause
  before_action :authorize_clock_resume!, only: :resume

  def show
    @clock_state.refresh!
    head :ok
  end

  def start
    @clock_state.start!

    redirect_to club_tournament_clock_path(@club, @tournament),
                notice: "Relógio iniciado com sucesso."
  rescue TournamentClockState::InvalidTransition
    redirect_to club_tournament_clock_path(@club, @tournament),
                alert: "O relógio não pode ser iniciado no estado atual."
  end

  def pause
    @clock_state.pause!

    redirect_to club_tournament_clock_path(@club, @tournament),
                notice: "Relógio pausado com sucesso."
  rescue TournamentClockState::InvalidTransition
    redirect_to club_tournament_clock_path(@club, @tournament),
                alert: "O relógio não pode ser pausado no estado atual."
  end

  def resume
    @clock_state.resume!

    redirect_to club_tournament_clock_path(@club, @tournament),
                notice: "Relógio retomado com sucesso."
  rescue TournamentClockState::InvalidTransition
    redirect_to club_tournament_clock_path(@club, @tournament),
                alert: "O relógio não pode ser retomado no estado atual."
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

  def set_clock_state
    return if performed?

    @clock_state = TournamentClockState.create_initial_for!(@tournament)
  end

  def authorize_clock_operation!
    return if performed? || @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end

  def authorize_clock_pause!
    return if performed? || @current_membership.owner? ||
              @current_membership.admin? || @current_membership.dealer?

    render plain: "Forbidden", status: :forbidden
  end

  def authorize_clock_resume!
    return if performed? || @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end
end
