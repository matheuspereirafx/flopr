class SubscriptionUpgradeService
  class Error < StandardError; end

  def initialize(user:)
    @user = user
  end

  def create_upgrade(new_plan, club)
    current_subscription = club.active_club_subscription
    raise Error, "Assinatura atual não encontrada." unless current_subscription
    raise Error, "O plano escolhido deve ser superior ao atual." unless upgrade_plan?(current_subscription, new_plan)
    raise Error, "O ciclo de cobrança precisa ser o mesmo." unless same_billing_period?(current_subscription, new_plan)

    result = SubscriptionProrationCalculator.new(
      current_subscription: current_subscription,
      new_plan: new_plan
    ).call
    raise Error, "Não há valor adicional para este upgrade." if result.upgrade_amount.zero?

    external_reference = "club_upgrade:#{SecureRandom.uuid}"
    new_subscription, upgrade = create_local_records(
      current_subscription,
      new_plan,
      result,
      external_reference
    )

    payment_id = Asaas::PaymentService.new(user: @user).create_upgrade_payment(upgrade)

    ClubSubscription.transaction do
      upgrade.update!(asaas_payment_id: payment_id)
      new_subscription.club_subscription_payments.create!(
        provider: "asaas",
        provider_payment_id: payment_id,
        provider_status: "PENDING",
        status: :pending,
        amount: upgrade.upgrade_amount
      )
    end

    upgrade
  rescue Asaas::Error
    mark_failed(upgrade) if defined?(upgrade) && upgrade&.persisted?
    raise
  end

  private

  def create_local_records(current_subscription, new_plan, result, external_reference)
    ClubSubscription.transaction do
      new_subscription = ClubSubscription.create!(
        club: current_subscription.club,
        plan: new_plan,
        owner: current_subscription.owner,
        status: :pending,
        billing_period: new_plan.billing_period,
        expires_at: result.period_ends_at
      )
      upgrade = SubscriptionUpgrade.create!(
        club: current_subscription.club,
        current_subscription: current_subscription,
        new_subscription: new_subscription,
        current_plan: current_subscription.plan,
        new_plan: new_plan,
        requested_by: @user,
        status: :pending_payment,
        original_amount: result.original_amount,
        credit_amount: result.credit_amount,
        upgrade_amount: result.upgrade_amount,
        period_started_at: result.period_started_at,
        period_ends_at: result.period_ends_at,
        external_reference: external_reference
      )
      [new_subscription, upgrade]
    end
  end

  def upgrade_plan?(current_subscription, new_plan)
    new_plan.active? && new_plan.price.to_d > current_subscription.plan.price.to_d
  end

  def same_billing_period?(current_subscription, new_plan)
    current_subscription.billing_period == new_plan.billing_period
  end

  def mark_failed(upgrade)
    upgrade.update_columns(
      status: "failed",
      failed_at: Time.current,
      failure_reason: "Não foi possível criar a cobrança do upgrade."
    )
  end
end
