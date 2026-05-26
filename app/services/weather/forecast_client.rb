# frozen_string_literal: true

module Weather
  # Retrieves weather forecast data from coordinates and normalizes the API response.
  class ForecastClient
    BASE_URL = "https://api.open-meteo.com"
    ERROR_MESSAGE = "Could not retrieve the weather forecast. Please try again."

    def self.call(zip_code:, submitted_address:, latitude:, longitude:)
      new(
        zip_code: zip_code,
        submitted_address: submitted_address,
        latitude: latitude,
        longitude: longitude
      ).call
    end

    def initialize(zip_code:, submitted_address:, latitude:, longitude:)
      @zip_code = zip_code
      @submitted_address = submitted_address
      @latitude = latitude
      @longitude = longitude
    end

    def call
      response = connection.get("/v1/forecast", request_params)

      return ApplicationResult.failure(ERROR_MESSAGE) unless response.success?

      ApplicationResult.success(build_forecast(JSON.parse(response.body)))
    rescue Faraday::Error, JSON::ParserError, KeyError
      # The UI should receive a stable error message instead of leaking API details.
      ApplicationResult.failure(ERROR_MESSAGE)
    end

    private

    def request_params
      {
        latitude: @latitude,
        longitude: @longitude,
        current: "temperature_2m,weather_code",
        daily: "temperature_2m_max,temperature_2m_min",
        temperature_unit: "fahrenheit",
        timezone: "auto",
        forecast_days: 1
      }
    end

    def build_forecast(body)
      current = body.fetch("current")
      daily = body.fetch("daily")

      WeatherForecast.new(
        submitted_address: @submitted_address,
        zip_code: @zip_code,
        current_temperature: current.fetch("temperature_2m"),
        high_temperature: daily.fetch("temperature_2m_max").fetch(0),
        low_temperature: daily.fetch("temperature_2m_min").fetch(0),
        description: Weather::WeatherCodeMapper.call(current.fetch("weather_code")),
        from_cache: false
      )
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |faraday|
        faraday.options.timeout = 5
        faraday.options.open_timeout = 2
      end
    end
  end
end
