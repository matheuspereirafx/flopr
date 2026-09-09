class CreateTournamentPrizePositions < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_prize_positions do |t|
      t.references :tournament_prize_pool, null: false, foreign_key: true
      t.integer :position, null: false
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.timestamps
    end

    add_index :tournament_prize_positions, %i[tournament_prize_pool_id position],
              unique: true, name: "index_prize_positions_on_pool_and_position"
    add_check_constraint :tournament_prize_positions, "position > 0",
                         name: "tournament_prize_positions_position_positive"
    add_check_constraint :tournament_prize_positions,
                         "percentage >= 0 AND percentage <= 100",
                         name: "tournament_prize_positions_percentage_in_range"
  end
end
