class CreateTournamentChargeOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_charge_options do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :name
      t.decimal :amount, precision: 10, scale: 2
      t.integer :chip_amount
      t.boolean :active, null: false, default: false
      t.references :available_from_level,
                   foreign_key: { to_table: :blind_levels }
      t.references :available_until_level,
                   foreign_key: { to_table: :blind_levels }
      t.timestamps
    end

    add_index :tournament_charge_options,
              %i[tournament_id kind],
              unique: true
    add_check_constraint :tournament_charge_options,
                         "amount IS NULL OR amount >= 0",
                         name: "tournament_charge_options_amount_non_negative"
    add_check_constraint :tournament_charge_options,
                         "chip_amount IS NULL OR chip_amount >= 0",
                         name: "tournament_charge_options_chips_non_negative"
  end
end
