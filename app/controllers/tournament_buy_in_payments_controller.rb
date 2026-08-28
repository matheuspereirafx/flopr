class TournamentBuyInPaymentsController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :set_registration

  def create
    if @registration.confirmed?
      redirect_to club_tournament_path(@club, @tournament),
                  notice: "Sua inscrição já está confirmada."
      return
    end

    @registration.with_lock do
      buy_in = @tournament.charge_options.find_by!(kind: :buy_in, active: true)

      pending_buy_in_payment || @registration.registration_payments.create!(
        tournament_charge_option: buy_in,
        recorded_by: current_user,
        amount: buy_in.amount,
        status: :pending,
        provider: "manual",
        payment_method: "manual"
      )
    end

    redirect_to club_tournament_path(@club, @tournament, payment: "buy_in"),
                notice: "Pagamento informado. Aguarde a confirmação do organizador."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    redirect_to club_tournament_path(@club, @tournament, payment: "buy_in"),
                alert: "Não foi possível criar a cobrança do buy-in."
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

  def pending_buy_in_payment
    @registration.registration_payments
                 .joins(:tournament_charge_option)
                 .where(status: :pending, tournament_charge_options: { kind: :buy_in })
                 .order(created_at: :desc)
                 .first
  end
end
