class TournamentRechargesController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :authorize_player!
  before_action :set_registration
  before_action :load_recharge_data

  def index
  end

  def create
    charge_option = available_recharge_options.find do |option|
      option.id.to_s == recharge_params[:tournament_charge_option_id].to_s
    end

    unless charge_option
      redirect_to recharges_path,
                  alert: "Esta recarga não está disponível no momento."
      return
    end

    @registration.with_lock do
      unless @registration.can_request_recharge?
        redirect_to recharges_path,
                    alert: "Aguarde alguns segundos antes de solicitar outra recarga."
        return
      end

      fee = selected_fee if include_fee?
      payments = [charge_option, fee].compact
      payment_group = @registration.registration_payment_groups.create!(
        total_amount: payments.sum { |option| option.amount.to_d },
        total_chip_amount: payments.sum { |option| option.chip_amount.to_i },
        status: :pending
      )

      payments.each do |option|
        @registration.registration_payments.create!(
          registration_payment_group: payment_group,
          tournament_charge_option: option,
          recorded_by: current_user,
          amount: option.amount,
          chip_amount: option.chip_amount,
          status: :pending,
          provider: "manual",
          payment_method: "manual"
        )
      end
    end

    redirect_to recharges_path,
                notice: "Solicitação de recarga enviada com sucesso."
  rescue ActiveRecord::RecordInvalid
    redirect_to recharges_path,
                alert: "Não foi possível solicitar esta recarga."
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

    @registration = @tournament.tournament_registrations.confirmed.find_by!(
      user: current_user
    )
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def authorize_player!
    return if performed?
    return if @current_membership.player?

    render plain: "Forbidden", status: :forbidden
  end

  def load_recharge_data
    return if performed?

    @available_charge_options = available_recharge_options
    @fee_option = selected_fee
    @recharge_history = @registration.registration_payments
                                                   .includes(:tournament_charge_option)
                                                   .order(created_at: :desc)
    @can_request_recharge = @registration.can_request_recharge?
  end

  def available_charge_options
    active_options = @tournament.charge_options.where(active: true).reject(&:buy_in?)
    clock_state = @tournament.clock_state

    return active_options unless clock_state&.current_blind_level

    active_options.select do |option|
      option.available_from_level&.level.to_i <= clock_state.current_blind_level.level &&
        (option.available_until_level.blank? ||
          option.available_until_level.level >= clock_state.current_blind_level.level)
    end
  end

  def available_recharge_options
    available_charge_options.reject(&:fee?)
  end

  def selected_fee
    available_charge_options.find(&:fee?)
  end

  def include_fee?
    ActiveModel::Type::Boolean.new.cast(recharge_params[:include_fee]) && selected_fee.present?
  end

  def recharge_params
    params.require(:registration_payment).permit(:tournament_charge_option_id, :include_fee)
  end

  def recharges_path
    club_tournament_recharges_path(@club, @tournament)
  end
end
