class TournamentBuyInPaymentsController < ApplicationController
  before_action :set_member_club
  before_action :set_tournament
  before_action :set_registration

  def create
    cpf = buy_in_params[:cpf]
    if cpf.present?
      current_user.cpf = cpf
      unless current_user.valid?
        redirect_to club_tournament_path(@club, @tournament),
                    alert: "Informe um CPF válido para continuar."
        return
      end
      current_user.save!
    end
    if current_user.cpf.blank?
      redirect_to club_tournament_path(@club, @tournament),
                  alert: "Informe um CPF válido para continuar."
      return
    end

    customer = AsaasCustomer.find_or_create_for(current_user)
    payment = AsaasPaymentCreation.call(
      registration: @registration,
      charge_option: @tournament.charge_options.find_by!(kind: :buy_in, active: true),
      customer_id: customer["id"] || customer[:id],
      payment_method: :pix
    )

    if payment.provider_payment_url.present?
      redirect_to payment.provider_payment_url, allow_other_host: true
    else
      redirect_to club_tournament_path(@club, @tournament),
                  notice: "Cobrança Pix criada. Aguardando pagamento."
    end
  rescue ActiveRecord::RecordInvalid, AsaasCustomer::InvalidCustomer,
         AsaasPaymentCreation::InvalidPayment, AsaasClient::Error
    redirect_to club_tournament_path(@club, @tournament),
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

  def buy_in_params
    params.fetch(:user, {}).permit(:cpf)
  end
end
