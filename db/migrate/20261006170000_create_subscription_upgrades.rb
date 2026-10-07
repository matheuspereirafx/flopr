class CreateSubscriptionUpgrades < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_upgrades do |t|
      t.references :club, null: false, foreign_key: true
      t.references :current_subscription, null: false, foreign_key: { to_table: :club_subscriptions }
      t.references :new_subscription, null: false, foreign_key: { to_table: :club_subscriptions }
      t.references :current_plan, null: false, foreign_key: { to_table: :plans }
      t.references :new_plan, null: false, foreign_key: { to_table: :plans }
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending_payment"
      t.decimal :original_amount, null: false, precision: 10, scale: 2
      t.decimal :credit_amount, null: false, precision: 10, scale: 2
      t.decimal :upgrade_amount, null: false, precision: 10, scale: 2
      t.datetime :period_started_at, null: false
      t.datetime :period_ends_at, null: false
      t.string :asaas_payment_id
      t.string :asaas_subscription_id
      t.string :external_reference, null: false
      t.datetime :applied_at
      t.datetime :failed_at
      t.text :failure_reason
      t.timestamps
    end

    add_index :subscription_upgrades, :status
    add_index :subscription_upgrades, :asaas_payment_id, unique: true, where: "asaas_payment_id IS NOT NULL"
    add_index :subscription_upgrades, :asaas_subscription_id, unique: true, where: "asaas_subscription_id IS NOT NULL"
    add_index :subscription_upgrades, :external_reference, unique: true
    add_index :subscription_upgrades, :club_id, unique: true, where: "status IN ('pending_payment', 'payment_approved', 'provider_sync_pending')", name: "index_pending_subscription_upgrades_on_club_id"
    add_check_constraint :subscription_upgrades, "original_amount >= 0", name: "subscription_upgrades_original_amount_non_negative"
    add_check_constraint :subscription_upgrades, "credit_amount >= 0", name: "subscription_upgrades_credit_amount_non_negative"
    add_check_constraint :subscription_upgrades, "upgrade_amount >= 0", name: "subscription_upgrades_upgrade_amount_non_negative"
  end
end
