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
    @paid_total = @transactions.paid.sum(:amount)
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
