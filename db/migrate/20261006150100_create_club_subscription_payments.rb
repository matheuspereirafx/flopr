class CreateClubSubscriptionPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :club_subscription_payments do |t|
      t.references :club_subscription, null: false, foreign_key: true
      t.string :provider, null: false, default: "asaas"
      t.string :provider_payment_id
      t.string :provider_status
      t.string :status, null: false, default: "pending"
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.datetime :paid_at
      t.text :failure_reason

      t.timestamps
    end

    add_index :club_subscription_payments, :status
    add_index :club_subscription_payments,
              %i[provider provider_payment_id],
              unique: true,
              where: "provider_payment_id IS NOT NULL",
              name: "index_club_subscription_payments_on_provider_payment_id"
    add_check_constraint :club_subscription_payments,
                         "amount >= 0",
                         name: "club_subscription_payments_amount_non_negative"
  end
end
