class AddPixQrCodeToRegistrationPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_payments, :pix_qr_code_image, :text
    add_column :registration_payments, :pix_payload, :text
    add_column :registration_payments, :pix_expiration_date, :datetime
  end
end
