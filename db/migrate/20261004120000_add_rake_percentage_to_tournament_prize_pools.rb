class AddRakePercentageToTournamentPrizePools < ActiveRecord::Migration[8.1]
  def change
    add_column :tournament_prize_pools, :rake_percentage, :integer,
               null: false, default: 0

    add_check_constraint :tournament_prize_pools,
                         "rake_percentage >= 0 AND rake_percentage <= 100",
                         name: "tournament_prize_pools_rake_percentage_in_range"

    change_column_null :tournament_prize_pools, :total_amount, true
  end
end
