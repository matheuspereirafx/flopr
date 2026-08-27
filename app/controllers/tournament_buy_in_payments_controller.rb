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

    cpf = buy_in_params[:cpf]
    name = buy_in_params[:name]
    if cpf.present? || name.present?
      current_user.assign_attributes(buy_in_params.to_h.compact_blank)
      unless current_user.valid?
        redirect_to club_tournament_path(@club, @tournament, payment: "buy_in"),
                    alert: "Informe um nome e CPF válidos para continuar."
        return
      end
      current_user.save!
    end
    if current_user.cpf.blank? || current_user.name.blank?
      redirect_to club_tournament_path(@club, @tournament, payment: "buy_in"),
                  alert: "Informe seu nome e CPF para continuar."
      return
    end

    payment = nil
    @registration.with_lock do
      payment = @registration.registration_payments
                              .joins(:tournament_charge_option)
                              .where(status: :pending,
                                     tournament_charge_options: { kind: :buy_in })
                              .order(created_at: :desc)
                              .first

      unless payment
        customer = AsaasCustomer.find_or_create_for(current_user)
        payment = AsaasPaymentCreation.call(
          registration: @registration,
          charge_option: @tournament.charge_options.find_by!(kind: :buy_in, active: true),
          customer_id: customer["id"] || customer[:id],
          payment_method: :pix
        )
      end
    end

    redirect_to club_tournament_path(@club, @tournament, payment: "buy_in"),
                notice: "Cobrança Pix criada. Aguardando pagamento."
  rescue ActiveRecord::RecordInvalid, AsaasCustomer::InvalidCustomer,
         AsaasPaymentCreation::InvalidPayment, AsaasClient::Error
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

  def buy_in_params
    params.fetch(:user, {}).permit(:name, :cpf)
  end
end
