class AddCaseInsensitiveUniqueIndexToTournamentNames < ActiveRecord::Migration[8.1]
  def change
    add_index :tournaments,
              "LOWER(name)",
              unique: true,
              name: "index_tournaments_on_lower_name"
  end
end
