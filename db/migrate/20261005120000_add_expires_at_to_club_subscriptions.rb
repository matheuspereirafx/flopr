class AddExpiresAtToClubSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :club_subscriptions, :expires_at, :datetime
    add_index :club_subscriptions, :expires_at
  end
end
