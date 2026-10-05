class AddClockStartedAtToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :clock_started_at, :datetime
    add_index :tournaments, %i[club_id clock_started_at]
  end
end
