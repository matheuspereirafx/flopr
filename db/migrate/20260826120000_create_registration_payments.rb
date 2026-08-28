class CreateRegistrationPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_payments do |t|
      t.references :tournament_registration, null: false, foreign_key: true
      t.references :tournament_charge_option, null: false, foreign_key: true
      t.references :recorded_by,
                   null: false,
                   foreign_key: { to_table: :users }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "pending"
      t.string :provider, null: false
      t.string :provider_payment_id
      t.string :provider_status
      t.string :payment_method, null: false
      t.datetime :paid_at

      t.timestamps
    end

    add_index :registration_payments, :status
    add_index :registration_payments,
              %i[provider provider_payment_id],
              unique: true,
              where: "provider_payment_id IS NOT NULL"
    add_check_constraint :registration_payments,
                         "amount >= 0",
                         name: "registration_payments_amount_non_negative"
  end
end
