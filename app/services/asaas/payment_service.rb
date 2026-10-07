require "json"
require "net/http"

module Asaas
  class PaymentService
    def initialize(user:)
      @user = user
    end

    def create_upgrade_payment(upgrade)
      customer_id = SubscriptionService.new(user: @user).customer_id_for(upgrade.club)
      response = post(
        "/payments",
        customer: customer_id,
        billingType: "UNDEFINED",
        value: upgrade.upgrade_amount.to_f,
        dueDate: Date.current.to_s,
        description: "Upgrade para #{upgrade.new_plan.name}",
        externalReference: upgrade.external_reference
      )

      response.fetch("id")
    end

    private

    def post(path, payload)
      uri = URI.join(normalized_base_url, path.to_s.delete_prefix("/"))
      request = Net::HTTP::Post.new(uri)
      request["access_token"] = ENV.fetch("ASAAS_API_KEY")
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

    def normalized_base_url
      "#{ENV.fetch("ASAAS_API_URL", "https://api-sandbox.asaas.com/v3/").chomp("/")}/"
    end
  end
end
