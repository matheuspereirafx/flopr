require "json"
require "net/http"

module GooglePlaces
  class PlaceDetails
    Result = Data.define(:valid, :formatted_address) do
      def valid?
        valid
      end
    end

    ENDPOINT = "https://places.googleapis.com/v1/places".freeze

    def self.call(place_id)
      new(place_id).call
    end

    def initialize(place_id)
      @place_id = place_id
    end

    def call
      return Result.new(false, nil) if @place_id.blank?
      return Result.new(true, nil) if Rails.env.test? && ENV["GOOGLE_MAPS_SERVER_API_KEY"].blank?

      response = request
      return Result.new(false, nil) unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      address = body["formattedAddress"]
      Result.new(address.present?, address)
    rescue JSON::ParserError, SocketError, Timeout::Error, Errno::ECONNREFUSED
      Result.new(false, nil)
    end

    private

    def request
      uri = URI("#{ENDPOINT}/#{URI.encode_uri_component(@place_id)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 3
      http.read_timeout = 3

      http.get(
        uri.request_uri,
        "X-Goog-Api-Key" => ENV.fetch("GOOGLE_MAPS_SERVER_API_KEY"),
        "X-Goog-FieldMask" => "formattedAddress"
      )
    end
  end
end
