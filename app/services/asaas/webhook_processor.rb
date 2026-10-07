module Asaas
  class WebhookProcessor
    APPROVED_EVENTS = %w[PAYMENT_CONFIRMED PAYMENT_RECEIVED].freeze
    REJECTED_EVENTS = %w[PAYMENT_CREDIT_CARD_CAPTURE_REFUSED PAYMENT_OVERDUE].freeze
    CANCELED_SUBSCRIPTION_EVENTS = %w[SUBSCRIPTION_DELETED SUBSCRIPTION_INACTIVATED].freeze

    def initialize(payload:)
      @payload = payload
    end

    def call(event_id)
      existing_event = SubscriptionWebhookEvent.find_by(
        provider: "asaas",
        provider_event_id: event_id
      )
      return retry_existing_payment(existing_event) if existing_event&.pending_payment_retry?
      return :duplicate if existing_event

      ApplicationRecord.transaction do
        event = SubscriptionWebhookEvent.create!(
          provider: "asaas",
          provider_event_id: event_id,
          event_type: @payload.fetch("event"),
          payload: @payload
        )

        if APPROVED_EVENTS.include?(@payload["event"]) || REJECTED_EVENTS.include?(@payload["event"])
          process_payment(event)
        elsif CANCELED_SUBSCRIPTION_EVENTS.include?(@payload["event"])
          process_subscription_cancellation(event)
        end

        event
      end
    end

    private

    def process_payment(event)
      payment_data = @payload.fetch("payment", {})
      if payment_data["subscription"].present?
        process_subscription_payment(event, payment_data)
      elsif payment_data["externalReference"].present?
        upgrade = SubscriptionUpgrade.find_by(external_reference: payment_data["externalReference"])
        process_upgrade_payment(event, payment_data, upgrade) if upgrade
      end
    end

    def process_subscription_payment(event, payment_data)
      subscription = ClubSubscription.find_by(asaas_subscription_id: payment_data["subscription"])
      return unless subscription

      payment = subscription.club_subscription_payments.find_or_initialize_by(
        provider: "asaas",
        provider_payment_id: payment_data["id"]
      )
      payment.assign_attributes(
        provider_status: payment_data["status"],
        status: approved_event? ? :approved : :rejected,
        amount: payment_data.fetch("value", subscription.plan.price),
        paid_at: approved_event? ? Time.current : nil
      )
      payment.failure_reason = payment_data["description"] unless approved_event?
      payment.save!
      event.update!(club_subscription: subscription, club_subscription_payment: payment)

      activate_subscription!(subscription) if approved_event?
    end

    def process_upgrade_payment(event, payment_data, upgrade)
      payment = upgrade.new_subscription.club_subscription_payments.find_or_initialize_by(
        provider: "asaas",
        provider_payment_id: payment_data["id"]
      )
      payment.assign_attributes(
        provider_status: payment_data["status"],
        status: approved_event? ? :approved : :rejected,
        amount: payment_data.fetch("value", upgrade.upgrade_amount),
        paid_at: approved_event? ? Time.current : nil
      )
      payment.failure_reason = payment_data["description"] unless approved_event?
      payment.save!
      event.update!(club_subscription: upgrade.new_subscription, club_subscription_payment: payment)

      if approved_event?
        apply_upgrade!(upgrade)
      else
        upgrade.update!(status: :rejected)
        upgrade.new_subscription.update!(status: :canceled)
      end
    end

    def retry_existing_payment(event)
      ApplicationRecord.transaction do
        process_payment(event)
        event
      end
    end

    def process_subscription_cancellation(event)
      subscription_id = @payload.dig("subscription", "id")
      subscription = ClubSubscription.find_by(asaas_subscription_id: subscription_id)
      return unless subscription

      subscription.update!(provider_canceled_at: Time.current)
      event.update!(club_subscription: subscription)
    end

    def activate_subscription!(subscription)
      subscription.club.with_lock do
        subscription.club.club_subscriptions.active.where.not(id: subscription.id).find_each do |current_subscription|
          current_subscription.update!(status: :canceled)
        end

        started_at = subscription.expires_at&.future? ? subscription.expires_at : Time.current
        subscription.update!(
          status: :active,
          expires_at: subscription.plan.subscription_expires_at(started_at)
        )
      end
    end

    def apply_upgrade!(upgrade)
      return if upgrade.applied?

      upgrade.update!(status: :provider_sync_pending)
      subscription_service = Asaas::SubscriptionService.new(user: upgrade.requested_by)
      subscription_service.cancel_subscription(upgrade.current_subscription.asaas_subscription_id)

      unless upgrade.asaas_subscription_id.present?
        response = subscription_service.create_subscription(
          upgrade.new_plan,
          upgrade.club,
          next_due_date: upgrade.period_ends_at,
          external_reference: "club:#{upgrade.club_id}:upgrade:#{upgrade.id}"
        )
        upgrade.update!(asaas_subscription_id: response.fetch(:subscription_id))
      end

      ApplicationRecord.transaction do
        upgrade.club.with_lock do
          upgrade.club.club_subscriptions.active.where.not(id: upgrade.new_subscription_id).find_each do |current_subscription|
            current_subscription.update!(status: :canceled)
          end
          upgrade.new_subscription.update!(
            status: :active,
            asaas_subscription_id: upgrade.asaas_subscription_id,
            expires_at: upgrade.period_ends_at
          )
          upgrade.update!(status: :applied, applied_at: Time.current)
        end
      end
    end

    def approved_event?
      APPROVED_EVENTS.include?(@payload["event"])
    end
  end
end
