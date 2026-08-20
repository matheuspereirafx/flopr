class CreateTournamentRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_registrations do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :tournament_registrations,
              %i[tournament_id user_id],
              unique: true
    add_index :tournament_registrations, :status
  end
end
