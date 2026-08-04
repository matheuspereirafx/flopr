class AddOwnerToClubs < ActiveRecord::Migration[8.0]
  def change
    add_reference :clubs,
                  :owner,
                  foreign_key: { to_table: :users }
  end
end
