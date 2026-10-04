class MakePrizePositionPercentagesIntegers < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :tournament_prize_positions,
                           name: "tournament_prize_positions_percentage_in_range"

    change_column :tournament_prize_positions,
                  :percentage,
                  :integer,
                  using: "percentage::integer"

    add_check_constraint :tournament_prize_positions,
                         "percentage > 0 AND percentage <= 100",
                         name: "tournament_prize_positions_percentage_in_range"
  end

  def down
    remove_check_constraint :tournament_prize_positions,
                           name: "tournament_prize_positions_percentage_in_range"

    change_column :tournament_prize_positions,
                  :percentage,
                  :decimal,
                  precision: 5,
                  scale: 2

    add_check_constraint :tournament_prize_positions,
                         "percentage >= 0 AND percentage <= 100",
                         name: "tournament_prize_positions_percentage_in_range"
  end
end
