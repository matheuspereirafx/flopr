class CreateSubscriptionWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_webhook_events do |t|
      t.references :club_subscription, null: true, foreign_key: true
      t.references :club_subscription_payment, null: true, foreign_key: true
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :subscription_webhook_events,
              %i[provider provider_event_id],
              unique: true,
              name: "index_subscription_webhook_events_on_provider_event_id"
  end
end
