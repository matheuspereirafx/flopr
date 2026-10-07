class AddAsaasSubscriptionIdToSubscriptionChanges < ActiveRecord::Migration[8.1]
  def change
    add_column :subscription_changes, :asaas_subscription_id, :string
    add_index :subscription_changes, :asaas_subscription_id,
              unique: true,
              where: "asaas_subscription_id IS NOT NULL"
  end
end
