class TournamentInvitationLinksController < ApplicationController
  before_action :set_tournament

  def confirm
    TournamentRegistrationConfirmation.call(
      tournament: @tournament,
      user: current_user
    )

    redirect_to club_tournament_path(@tournament.club, @tournament),
                notice: "Presença confirmada com sucesso."
  rescue TournamentRegistrationConfirmation::CapacityReached
    redirect_to club_tournament_path(@tournament.club, @tournament),
                alert: "As vagas do torneio foram preenchidas."
  end

  private

  def set_tournament
    @tournament = Tournament.find_by!(invite_token: params[:token])
    raise ActiveRecord::RecordNotFound unless @tournament.invite_link_valid?
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
