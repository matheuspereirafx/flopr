class CreateRegistrationPaymentGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_payment_groups do |t|
      t.references :tournament_registration, null: false, foreign_key: true
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.integer :total_chip_amount, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :registration_payment_groups, :status
    add_check_constraint :registration_payment_groups,
                         "total_amount >= 0",
                         name: "registration_payment_groups_total_amount_non_negative"
    add_check_constraint :registration_payment_groups,
                         "total_chip_amount >= 0",
                         name: "registration_payment_groups_total_chips_non_negative"

    add_reference :registration_payments,
                  :registration_payment_group,
                  foreign_key: true
    add_column :registration_payments, :chip_amount, :integer
    add_check_constraint :registration_payments,
                         "chip_amount IS NULL OR chip_amount >= 0",
                         name: "registration_payments_chips_non_negative"
  end
end
