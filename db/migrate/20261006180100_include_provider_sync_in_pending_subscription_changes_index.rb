class IncludeProviderSyncInPendingSubscriptionChangesIndex < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_subscription_changes_on_pending_club"

  def change
    remove_index :subscription_changes, name: INDEX_NAME
    add_index :subscription_changes, :club_id,
              unique: true,
              where: "status IN ('pending', 'provider_sync_pending')",
              name: INDEX_NAME
  end
end
