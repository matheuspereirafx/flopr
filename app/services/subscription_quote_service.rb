class SubscriptionQuoteService
  Result = Data.define(
    :mode,
    :eligible,
    :current_plan_name,
    :new_plan_name,
    :new_plan_amount,
    :credit_amount,
    :amount_due,
    :next_renewal_at,
    :message
  )

  def initialize(club:, plan:, now: Time.current)
    @club = club
    @plan = plan
    @now = now
  end

  def call
    current_subscription = @club.active_club_subscription
    return initial_quote unless current_subscription
    return initial_quote(current_subscription) if current_subscription.plan.free?
    return same_plan_quote(current_subscription) if current_subscription.plan_id == @plan.id
    return incompatible_cycle_quote(current_subscription) if incompatible_cycle?(current_subscription)
    return downgrade_quote(current_subscription) if current_subscription.plan.downgrade_to?(@plan)

    upgrade_quote(current_subscription)
  end

  private

  def initial_quote(current_subscription = nil)
    Result.new(
      mode: "initial",
      eligible: true,
      current_plan_name: current_subscription&.plan&.name,
      new_plan_name: @plan.name,
      new_plan_amount: @plan.price.to_d,
      credit_amount: 0.to_d,
      amount_due: @plan.price.to_d,
      next_renewal_at: @plan.subscription_expires_at(@now),
      message: ""
    )
  end

  def same_plan_quote(current_subscription)
    Result.new(
      mode: "same_plan",
      eligible: false,
      current_plan_name: current_subscription.plan.name,
      new_plan_name: @plan.name,
      new_plan_amount: @plan.price.to_d,
      credit_amount: 0.to_d,
      amount_due: 0.to_d,
      next_renewal_at: current_subscription.expires_at,
      message: "Este plano já está ativo neste clube."
    )
  end

  def downgrade_quote(current_subscription)
    Result.new(
      mode: "downgrade",
      eligible: false,
      current_plan_name: current_subscription.plan.name,
      new_plan_name: @plan.name,
      new_plan_amount: @plan.price.to_d,
      credit_amount: 0.to_d,
      amount_due: 0.to_d,
      next_renewal_at: current_subscription.expires_at,
      message: "A redução será agendada para a renovação da assinatura atual."
    )
  end

  def incompatible_cycle_quote(current_subscription)
    Result.new(
      mode: "incompatible_cycle",
      eligible: false,
      current_plan_name: current_subscription.plan.name,
      new_plan_name: @plan.name,
      new_plan_amount: @plan.price.to_d,
      credit_amount: 0.to_d,
      amount_due: 0.to_d,
      next_renewal_at: current_subscription.expires_at,
      message: "A troca entre ciclos mensal e anual ainda não está disponível."
    )
  end

  def upgrade_quote(current_subscription)
    result = SubscriptionProrationCalculator.new(
      current_subscription: current_subscription,
      new_plan: @plan,
      now: @now
    ).call

    Result.new(
      mode: "upgrade",
      eligible: true,
      current_plan_name: current_subscription.plan.name,
      new_plan_name: @plan.name,
      new_plan_amount: @plan.price.to_d,
      credit_amount: result.credit_amount,
      amount_due: result.upgrade_amount,
      next_renewal_at: result.period_ends_at,
      message: ""
    )
  end

  def incompatible_cycle?(current_subscription)
    !current_subscription.plan.free? &&
      current_subscription.billing_period != @plan.billing_period &&
      @plan.price.to_d > current_subscription.plan.price.to_d
  end
end
