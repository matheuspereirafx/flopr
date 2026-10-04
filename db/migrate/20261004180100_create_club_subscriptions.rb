class CreateClubSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :club_subscriptions do |t|
      t.references :club, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "active"
      t.string :billing_period, null: false

      t.timestamps
    end

    add_index :club_subscriptions, :status
    add_index :club_subscriptions, %i[club_id],
              unique: true,
              where: "status = 'active'",
              name: "index_club_subscriptions_on_active_club"
  end
end
