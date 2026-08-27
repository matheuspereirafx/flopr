class AddProviderPaymentUrl < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_payments, :provider_payment_url, :string
  end
end
