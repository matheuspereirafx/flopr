class ApplySubscriptionChangesJob < ApplicationJob
  queue_as :default

  def perform
    SubscriptionChange.due.find_each do |subscription_change|
      apply_change(subscription_change)
    end
  end

  private

  def apply_change(subscription_change)
    change = prepare_change(subscription_change)
    return unless change

    synchronize_provider(change)
    finalize_change(change)
  rescue Asaas::Error
    change&.update!(status: :pending) if change&.persisted? && change.provider_sync_pending?
    raise
  end

  def prepare_change(subscription_change)
    SubscriptionChange.transaction do
      change = SubscriptionChange.lock.find(subscription_change.id)
      next unless change.pending? && change.effective_at <= Time.current

      change.update!(status: :provider_sync_pending)
      change
    end
  end

  def synchronize_provider(change)
    service = Asaas::SubscriptionService.new(user: change.club_subscription.owner)

    unless change.new_plan.free?
      if change.asaas_subscription_id.blank?
        response = service.create_subscription(
          change.new_plan,
          change.club,
          next_due_date: [change.effective_at.to_date, Date.current].max,
          external_reference: "club:#{change.club_id}:downgrade:#{change.id}"
        )
        change.update!(asaas_subscription_id: response.fetch(:subscription_id))
      end
    end

    service.cancel_subscription(change.club_subscription.asaas_subscription_id)
  end

  def finalize_change(change)
    ApplicationRecord.transaction do
      change = SubscriptionChange.lock.find(change.id)
      return unless change.provider_sync_pending?

      subscription = change.club_subscription.lock!
      subscription.update!(status: :expired)

      change.club.club_subscriptions.create!(
        plan: change.new_plan,
        owner: subscription.owner,
        status: :active,
        billing_period: change.new_plan.billing_period,
        expires_at: change.new_plan.subscription_expires_at(change.effective_at),
        asaas_subscription_id: change.asaas_subscription_id
      )

      change.update!(status: :applied, applied_at: Time.current)
    end
  end
end
