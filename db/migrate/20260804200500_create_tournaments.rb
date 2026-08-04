class CreateTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :tournaments do |t|
      t.references :club, null: false, foreign_key: true
      t.string :name, null: false
      t.string :location, null: false
      t.integer :max_players, null: false
      t.datetime :starts_at, null: false
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :tournaments, :status
    add_index :tournaments, :starts_at
    add_index :tournaments, [:club_id, :starts_at]
  end
end
