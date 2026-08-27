require "net/http"
require "json"

class AsaasClient
  class Error < StandardError; end

  def initialize(
    api_key: ENV.fetch("ASAAS_API_KEY"),
    base_url: ENV.fetch("ASAAS_BASE_URL", "https://api-sandbox.asaas.com/v3")
  )
    @api_key = api_key
    @base_url = base_url
  end

  def create_customer(user)
    post("customers", {
      name: user.name,
      email: user.email,
      cpfCnpj: user.cpf,
      externalReference: "user_#{user.id}"
    })
  end

  def create_payment(registration, charge_option, customer_id)
    post("payments", {
      customer: customer_id,
      billingType: "PIX",
      value: charge_option.amount.to_f,
      dueDate: Date.current.iso8601,
      description: "Buy-in - #{registration.tournament.name}",
      externalReference: "registration_#{registration.id}"
    })
  end

  def pix_qr_code(payment_id)
    get("payments/#{payment_id}/pixQrCode")
  end

  private

  def get(path)
    uri = URI.join("#{@base_url}/", path)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Flopr/1.0"
    request["access_token"] = @api_key

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    body = JSON.parse(response.body)
    return body if response.is_a?(Net::HTTPSuccess)

    raise Error, body.dig("errors", 0, "description") || "Erro na API do Asaas"
  rescue JSON::ParserError
    raise Error, "Resposta inválida da API do Asaas"
  end

  def post(path, payload)
    uri = URI.join("#{@base_url}/", path)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "Flopr/1.0"
    request["access_token"] = @api_key
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    body = JSON.parse(response.body)
    return body if response.is_a?(Net::HTTPSuccess)

    raise Error, body.dig("errors", 0, "description") || "Erro na API do Asaas"
  rescue JSON::ParserError
    raise Error, "Resposta inválida da API do Asaas"
  end
end
