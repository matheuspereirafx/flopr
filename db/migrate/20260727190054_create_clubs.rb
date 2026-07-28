class CreateClubs < ActiveRecord::Migration[8.1]
  def change
    create_table :clubs do |t|
      t.string :name
      t.string :whatsapp_contact_number

      t.timestamps
    end
  end
end
