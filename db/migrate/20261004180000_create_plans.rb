class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :billing_period, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :plans, :name, unique: true
    add_index :plans, :active
    add_check_constraint :plans, "price >= 0", name: "plans_price_non_negative"
  end
end
