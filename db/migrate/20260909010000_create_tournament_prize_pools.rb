class CreateTournamentPrizePools < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_prize_pools do |t|
      t.references :tournament, null: false, foreign_key: true, index: { unique: true }
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.timestamps
    end

    add_check_constraint :tournament_prize_pools, "total_amount > 0",
                         name: "tournament_prize_pools_total_amount_positive"
  end
end
