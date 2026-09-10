class AddGooglePlaceIdToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :google_place_id, :string
    add_index :tournaments, :google_place_id
  end
end
