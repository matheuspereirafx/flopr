class CreateTournamentCreations < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_creations do |t|
      t.references :club, null: false, foreign_key: true
      t.timestamps
    end

    add_index :tournament_creations, %i[club_id created_at]
  end
end
