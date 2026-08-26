class TournamentBuyInPaymentsController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :set_registration

  def create
    TournamentBuyInPayment.call(
      registration: @registration,
      user: current_user
    )

    redirect_to club_tournament_path(@club, @tournament),
                notice: "Buy-in pago com sucesso. Sua inscrição está confirmada."
  rescue TournamentBuyInPayment::InvalidPayment
    redirect_to club_tournament_path(@club, @tournament),
                alert: "Não foi possível confirmar o pagamento do buy-in."
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

  def set_registration
    return if performed?

    @registration = @tournament.tournament_registrations.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
