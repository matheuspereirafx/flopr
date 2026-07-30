class RemoveOwnerFromClubs < ActiveRecord::Migration[8.1]
  def change
    remove_column :clubs, :owner_id, :bigint
  end
end
