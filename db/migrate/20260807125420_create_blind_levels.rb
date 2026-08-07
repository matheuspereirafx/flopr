class CreateBlindLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :blind_levels do |t|
      t.references :tournament, null: false, foreign_key: true
      t.integer :level, null: false
      t.integer :duration_minutes, null: false
      t.integer :small_blind, null: false
      t.integer :big_blind, null: false
      t.integer :ante, null: false, default: 0

      t.timestamps
    end

    add_index :blind_levels, [:tournament_id, :level], unique: true
  end
end
