require "json"
require "net/http"

module Asaas
  class Error < StandardError; end unless const_defined?(:Error)

  class SubscriptionService
    def initialize(user:)
      @user = user
    end

    def create_subscription(plan, club)
      customer_id = @user.asaas_customer_id.presence
      response = post(
        "/customers",
        customer_payload(club, customer_id)
      ) unless customer_id

      customer_id ||= response.fetch("id")
      @user.update!(asaas_customer_id: customer_id) if @user.asaas_customer_id.blank?

      subscription = post(
        "/subscriptions",
        subscription_payload(plan, club, customer_id)
      )

      {
        customer_id: customer_id,
        subscription_id: subscription.fetch("id")
      }
    end

    private

    def customer_payload(club, _customer_id)
      {
        name: @user.name,
        email: @user.email,
        cpfCnpj: @user.cpf,
        externalReference: "user:#{@user.id}",
        notificationDisabled: false
      }.compact
    end

    def subscription_payload(plan, club, customer_id)
      {
        customer: customer_id,
        billingType: "UNDEFINED",
        value: plan.price.to_f,
        cycle: plan.monthly? ? "MONTHLY" : "YEARLY",
        description: plan.name,
        externalReference: "club:#{club.id}:plan:#{plan.id}",
        nextDueDate: Date.current.to_s
      }
    end

    def post(path, payload)
      uri = URI.join(normalized_base_url, path.to_s.delete_prefix("/"))
      request = Net::HTTP::Post.new(uri)
      request["access_token"] = api_key
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      parsed_response = JSON.parse(response.body)
      return parsed_response if response.is_a?(Net::HTTPSuccess)

      raise Error, parsed_response["errors"] || "Asaas request failed"
    rescue JSON::ParserError => error
      raise Error, error.message
    end

    def api_key
      ENV.fetch("ASAAS_API_KEY")
    end

    def base_url
      ENV.fetch("ASAAS_API_URL", "https://api-sandbox.asaas.com/v3/")
    end

    def normalized_base_url
      "#{base_url.chomp("/")}/"
    end
  end
end
