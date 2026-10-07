class SubscriptionProrationCalculator
  Result = Data.define(
    :period_started_at,
    :period_ends_at,
    :original_amount,
    :credit_amount,
    :upgrade_amount
  )

  def initialize(current_subscription:, new_plan:, now: Time.current)
    @current_subscription = current_subscription
    @new_plan = new_plan
    @now = now
  end

  def call
    period_ends_at = @current_subscription.expires_at || @new_plan.subscription_expires_at(@now)
    period_started_at = if @current_subscription.expires_at
                          period_ends_at - period_duration
                        else
                          @now
                        end
    original_amount = @current_subscription.plan.price.to_d
    credit_amount = calculate_credit(period_started_at, period_ends_at, original_amount)
    upgrade_amount = [@new_plan.price.to_d - credit_amount, 0.to_d].max.round(2)

    Result.new(
      period_started_at: period_started_at,
      period_ends_at: period_ends_at,
      original_amount: original_amount,
      credit_amount: credit_amount,
      upgrade_amount: upgrade_amount
    )
  end

  private

  def period_duration
    @current_subscription.billing_period == "yearly" ? 1.year : 1.month
  end

  def calculate_credit(period_started_at, period_ends_at, original_amount)
    return 0.to_d if original_amount.zero? || period_ends_at <= @now

    total_seconds = period_ends_at - period_started_at
    remaining_seconds = period_ends_at - [@now, period_started_at].max
    (original_amount * remaining_seconds / total_seconds).round(2)
  end
end
