class AddPixPaymentSettingsToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :pix_key, :string
    add_column :clubs, :pix_key_type, :string
    add_column :clubs, :pix_recipient_name, :string
  end
end
