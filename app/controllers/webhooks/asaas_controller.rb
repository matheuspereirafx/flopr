class Webhooks::AsaasController < ActionController::API
  def create
    payload = JSON.parse(request.raw_post)
    return head :bad_request if payload["id"].blank? || payload["event"].blank?
    return head :unauthorized unless valid_webhook_token?
    return head :ok if SubscriptionWebhookEvent.exists?(provider: "asaas", provider_event_id: payload["id"])

    result = Asaas::WebhookProcessor.new(payload: payload).call(payload.fetch("id"))
    return head :ok if result == :duplicate

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private

  def valid_webhook_token?
    expected_token = Rails.env.test? ? "test-token" : ENV.fetch("ASAAS_WEBHOOK_TOKEN")
    received_token = request.headers["asaas-access-token"].presence ||
      request.headers["X-Asaas-Webhook-Token"].presence

    received_token.present? &&
      ActiveSupport::SecurityUtils.secure_compare(received_token, expected_token)
  end
end
