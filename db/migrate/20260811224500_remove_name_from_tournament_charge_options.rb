class RemoveNameFromTournamentChargeOptions < ActiveRecord::Migration[8.1]
  def change
    remove_column :tournament_charge_options, :name, :string
  end
end
