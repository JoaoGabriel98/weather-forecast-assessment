# frozen_string_literal: true

module Weather
  # Resolves a US ZIP code into latitude and longitude.
  class GeocodingClient
    BASE_URL = "https://geocoding-api.open-meteo.com"
    ERROR_MESSAGE = "Could not resolve the ZIP code location. Please try again."

    def self.call(zip_code)
      new(zip_code).call
    end

    def initialize(zip_code)
      @zip_code = zip_code
    end

    def call
      response = connection.get("/v1/search", request_params)

      return ApplicationResult.failure(ERROR_MESSAGE) unless response.success?

      body = JSON.parse(response.body)
      location = body.fetch("results", []).first

      return ApplicationResult.failure("Could not find a location for ZIP code #{@zip_code}.") unless location

      ApplicationResult.success(
        latitude: location.fetch("latitude"),
        longitude: location.fetch("longitude")
      )
    rescue Faraday::Error, JSON::ParserError, KeyError
      ApplicationResult.failure(ERROR_MESSAGE)
    end

    private

    def request_params
      {
        name: @zip_code,
        count: 1,
        language: "en",
        format: "json",
        countryCode: "US"
      }
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |faraday|
        faraday.options.timeout = 5
        faraday.options.open_timeout = 2
      end
    end
  end
end
