class PaymentWebhooksController < ApplicationController
  skip_forgery_protection
  skip_before_action :authenticate_user!

  before_action :authenticate_asaas!

  def asaas
    return head :ok unless params[:event] == "PAYMENT_RECEIVED"

    provider_payment_id = params.dig(:payment, :id)
    payment = RegistrationPayment.find_by(
      provider: "asaas",
      provider_payment_id: provider_payment_id
    )
    return head :not_found unless payment

    ApplicationRecord.transaction do
      payment.with_lock do
        unless payment.paid?
          payment.update!(status: :paid, provider_status: "RECEIVED", paid_at: Time.current)
          payment.tournament_registration.update!(status: :confirmed) if payment.tournament_charge_option.buy_in?
        end
      end
    end

    head :ok
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private

  def authenticate_asaas!
    configured_token = ENV["ASAAS_WEBHOOK_TOKEN"]
    received_token = request.headers["asaas-access-token"]
    return if configured_token.present? && received_token.present? &&
              ActiveSupport::SecurityUtils.secure_compare(received_token, configured_token)

    head :unauthorized
  end
end
