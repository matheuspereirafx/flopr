class TournamentTransactionsController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :authorize_transactions_view!

  def index
    @transactions = @tournament.registration_payments
                                  .includes(
                                    tournament_registration: :user,
                                    tournament_charge_option: {},
                                    recorded_by: {}
                                  )
                                  .order(created_at: :desc)
    @pending_transactions = @transactions.pending
    @completed_transactions = @transactions.paid
    paid_transactions = @transactions.paid
    @paid_total = paid_transactions.sum(:amount)
    @paid_counts_by_kind = paid_transactions
                            .unscope(:order)
                            .joins(:tournament_charge_option)
                            .group("tournament_charge_options.kind")
                            .count
  end

  def confirm
    payment = @tournament.registration_payments.find(params[:id])

    payment.with_lock do
      unless payment.pending?
        redirect_to club_tournament_transactions_path(@club, @tournament),
                    alert: "Este pagamento não está pendente."
        return
      end

      payment.update!(status: :paid, paid_at: Time.current)
      payment.tournament_registration.update!(status: :confirmed) if payment.tournament_charge_option.buy_in?
    end

    redirect_to club_tournament_transactions_path(@club, @tournament),
                notice: "Pagamento confirmado com sucesso."
  rescue ActiveRecord::RecordInvalid
    redirect_to club_tournament_transactions_path(@club, @tournament),
                alert: "Não foi possível confirmar este pagamento."
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

  def authorize_transactions_view!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end
end
