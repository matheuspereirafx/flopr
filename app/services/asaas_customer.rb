class AsaasCustomer
  class InvalidCustomer < StandardError; end

  def self.find_or_create_for(user, gateway: AsaasClient.new)
    raise InvalidCustomer unless user.valid? && user.cpf.present?
    return { id: user.asaas_customer_id } if user.asaas_customer_id.present?

    customer = gateway.create_customer(user)
    customer_id = customer["id"] || customer[:id]
    raise InvalidCustomer if customer_id.blank?

    user.update!(asaas_customer_id: customer_id)
    customer
  rescue ActiveRecord::RecordInvalid
    raise InvalidCustomer
  end
end
