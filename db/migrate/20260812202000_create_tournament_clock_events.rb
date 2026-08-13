class CreateTournamentClockEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_clock_events do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :from_blind_level,
                   null: false,
                   foreign_key: { to_table: :blind_levels }
      t.references :to_blind_level,
                   null: false,
                   foreign_key: { to_table: :blind_levels }
      t.string :kind, null: false
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :tournament_clock_events, [:tournament_id, :occurred_at]
  end
end
