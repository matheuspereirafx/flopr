class CreateSubscriptionChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_changes do |t|
      t.references :club, null: false, foreign_key: true
      t.references :club_subscription, null: false, foreign_key: true
      t.references :current_plan, null: false, foreign_key: { to_table: :plans }
      t.references :new_plan, null: false, foreign_key: { to_table: :plans }
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.string :change_type, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :effective_at, null: false
      t.datetime :applied_at
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscription_changes, :status
    add_index :subscription_changes, :effective_at
    add_index :subscription_changes, :change_type
    add_index :subscription_changes, :club_id,
              unique: true,
              where: "status = 'pending'",
              name: "index_subscription_changes_on_pending_club"
  end
end
