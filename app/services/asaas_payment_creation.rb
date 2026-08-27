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
    raise InvalidPayment unless %i[pix card].include?(@payment_method.to_sym)
    raise InvalidPayment unless @charge_option.buy_in?
    raise InvalidPayment unless @registration.pending?
    raise InvalidPayment unless @registration.tournament_id == @charge_option.tournament_id

    response = @gateway.create_payment(
      @registration,
      @charge_option,
      @customer_id,
      payment_method: @payment_method
    )
    provider_payment_id = response["id"] || response[:id]
    raise InvalidPayment if provider_payment_id.blank?

    attributes = {
      tournament_registration: @registration,
      tournament_charge_option: @charge_option,
      recorded_by: @registration.user,
      amount: @charge_option.amount,
      status: :pending,
      provider: "asaas",
      payment_method: @payment_method,
      provider_payment_id: provider_payment_id,
      provider_status: response["status"] || response[:status],
      provider_payment_url: response["invoiceUrl"] || response[:invoiceUrl]
    }
    attributes.merge!(pix_attributes(provider_payment_id)) if @payment_method.to_sym == :pix
    RegistrationPayment.create!(attributes)
  rescue ActiveRecord::RecordInvalid, AsaasClient::Error
    @gateway.delete_payment(provider_payment_id) if provider_payment_id.present? && @gateway.respond_to?(:delete_payment)
    raise InvalidPayment
  end

  private

  def parse_expiration_date(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  end

  def pix_attributes(provider_payment_id)
    pix_qr_code = @gateway.pix_qr_code(provider_payment_id)

    {
      pix_qr_code_image: pix_qr_code["encodedImage"] || pix_qr_code[:encodedImage],
      pix_payload: pix_qr_code["payload"] || pix_qr_code[:payload],
      pix_expiration_date: parse_expiration_date(
        pix_qr_code["expirationDate"] || pix_qr_code[:expirationDate]
      )
    }
  end
end
