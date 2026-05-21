# frozen_string_literal: true

module Weather
  # GeocodingClient works with coordinates, not addresses. Here we translate it
  class GeocodingClient
    BASE_URL = "https://geocoding-api.open-meteo.com"

    def self.call(zip_code)
      new(zip_code).call
    end

    def initialize(zip_code)
      @zip_code = zip_code
    end

    def call
      response = connection.get("/v1/search", {
        name: @zip_code,
        count: 1,
        language: "en",
        format: "json",
        countryCode: "US"
      })

      body = JSON.parse(response.body)
      location = body.fetch("results", []).first

      return ApplicationResult.failure("Could not find #{@zip_code}.") unless location

      ApplicationResult.success({
        latitude: location.fetch("latitude"),
        longitude: location.fetch("longitude")
      })
    rescue Faraday::Error, JSON::ParserError, KeyError
      ApplicationResult.failure("Please try again.")
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |faraday|
        faraday.options.timeout = 5
        faraday.options.open_timeout = 2
      end
    end
  end
end
