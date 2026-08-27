class AsaasPaymentCreation
  class InvalidPayment < StandardError; end

  def self.call(registration:, charge_option:, customer_id:, payment_method:, gateway: AsaasClient.new)
    new(registration:, charge_option:, customer_id:, payment_method:, gateway:).call
  end

  def initialize(registration:, charge_option:, customer_id:, payment_method:, gateway:)
    @registration = registration
    @charge_option = charge_option
    @customer_id = customer_id
    @payment_method = payment_method
    @gateway = gateway
  end

  def call
    raise InvalidPayment if @customer_id.blank?
    raise InvalidPayment unless @payment_method.to_sym == :pix
    raise InvalidPayment unless @charge_option.buy_in?
    raise InvalidPayment unless @registration.pending?
    raise InvalidPayment unless @registration.tournament_id == @charge_option.tournament_id

    payment = RegistrationPayment.create!(
      tournament_registration: @registration,
      tournament_charge_option: @charge_option,
      recorded_by: @registration.user,
      amount: @charge_option.amount,
      status: :pending,
      provider: "asaas",
      payment_method: "pix"
    )

    response = @gateway.create_payment(@registration, @charge_option, @customer_id)
    provider_payment_id = response["id"] || response[:id]
    raise InvalidPayment if provider_payment_id.blank?

    payment.update!(provider_payment_id: provider_payment_id,
                    provider_status: response["status"] || response[:status],
                    provider_payment_url: response["invoiceUrl"] || response[:invoiceUrl])
    payment
  rescue ActiveRecord::RecordInvalid, AsaasClient::Error
    raise InvalidPayment
  end
end
