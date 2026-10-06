class ApplySubscriptionChangesJob < ApplicationJob
  queue_as :default

  def perform
    SubscriptionChange.due.find_each do |subscription_change|
      apply_change(subscription_change)
    end
  end

  private

  def apply_change(subscription_change)
    SubscriptionChange.transaction do
      change = SubscriptionChange.lock.find(subscription_change.id)
      next unless change.pending? && change.effective_at <= Time.current

      subscription = change.club_subscription.lock!
      subscription.update!(status: :expired)

      change.club.club_subscriptions.create!(
        plan: change.new_plan,
        owner: subscription.owner,
        status: :active,
        billing_period: change.new_plan.billing_period,
        expires_at: change.new_plan.subscription_expires_at(change.effective_at)
      )

      change.update!(status: :applied, applied_at: Time.current)
    end
  end
end
