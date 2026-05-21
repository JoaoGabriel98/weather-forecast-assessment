# frozen_string_literal: true

module Weather
  # API call after we get the coordinates for the address. This is where we get the weather data.
  class ForecastClient
    BASE_URL = "https://api.open-meteo.com"

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
      body = JSON.parse(response.body)

      ApplicationResult.success(build_forecast(body))
    rescue Faraday::Error, JSON::ParserError, KeyError, NoMethodError
      # The UI should receive a stable error message instead of leaking API details.
      ApplicationResult.failure("Could not retrieve the weather forecast. Please try again.")
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
        high_temperature: daily.fetch("temperature_2m_max").first,
        low_temperature: daily.fetch("temperature_2m_min").first,
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
