class CreateTournamentClockStates < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_clock_states do |t|
      t.references :tournament,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }
      t.references :current_blind_level,
                   null: false,
                   foreign_key: { to_table: :blind_levels }
      t.integer :remaining_seconds, null: false, default: 0
      t.integer :overtime_elapsed_seconds, null: false, default: 0
      t.string :status, null: false, default: "not_started"
      t.datetime :started_at
      t.datetime :paused_at
      t.datetime :overtime_started_at

      t.timestamps
    end

    add_check_constraint :tournament_clock_states,
                         "remaining_seconds >= 0",
                         name: "tournament_clock_states_remaining_seconds_non_negative"
    add_check_constraint :tournament_clock_states,
                         "overtime_elapsed_seconds >= 0",
                         name: "tournament_clock_states_overtime_elapsed_seconds_non_negative"
  end
end
