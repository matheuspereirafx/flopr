class AddAsaasDataToClubSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :club_subscriptions, :asaas_subscription_id, :string
    add_column :club_subscriptions, :provider_canceled_at, :datetime

    add_index :club_subscriptions,
              :asaas_subscription_id,
              unique: true,
              where: "asaas_subscription_id IS NOT NULL"
  end
end
