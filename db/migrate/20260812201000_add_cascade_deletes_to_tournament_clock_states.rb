class AddCascadeDeletesToTournamentClockStates < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :tournament_clock_states, :tournaments
    remove_foreign_key :tournament_clock_states,
                       :blind_levels,
                       column: :current_blind_level_id

    add_foreign_key :tournament_clock_states,
                    :tournaments,
                    on_delete: :cascade
    add_foreign_key :tournament_clock_states,
                    :blind_levels,
                    column: :current_blind_level_id,
                    on_delete: :cascade
  end
end
