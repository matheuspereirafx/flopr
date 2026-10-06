class AddDowngradeMetadataToPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :plans, :tier, :integer, null: false, default: 0
    add_column :plans, :features, :string, array: true, null: false, default: []

    add_index :plans, :tier
  end
end
