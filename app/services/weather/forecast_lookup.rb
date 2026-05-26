# frozen_string_literal: true

module Weather
  # Application service that orchestrates forecast lookup for a submitted address.
  class ForecastLookup
    CACHE_EXPIRATION = 30.minutes

    def self.call(address:)
      new(address: address).call
    end

    def initialize(address:)
      @address = address.to_s
    end

    def call
      return ApplicationResult.failure("Please enter an address.") if @address.blank?

      zip_code = AddressZipExtractor.call(@address)

      return ApplicationResult.failure("Please include a valid US ZIP code in the address.") unless zip_code

      cached_forecast = Rails.cache.read(cache_key(zip_code))
      return ApplicationResult.success(forecast_for_current_request(cached_forecast, from_cache: true)) if cached_forecast

      fresh_forecast_result = fetch_fresh_forecast(zip_code)
      return fresh_forecast_result if fresh_forecast_result.failure?

      Rails.cache.write(cache_key(zip_code), fresh_forecast_result.value, expires_in: CACHE_EXPIRATION)

      ApplicationResult.success(forecast_for_current_request(fresh_forecast_result.value, from_cache: false))
    end

    private

    def fetch_fresh_forecast(zip_code)
      location_result = Weather::GeocodingClient.call(zip_code)
      return location_result if location_result.failure?

      Weather::ForecastClient.call(
        zip_code: zip_code,
        submitted_address: @address,
        latitude: location_result.value.fetch(:latitude),
        longitude: location_result.value.fetch(:longitude)
      )
    end

    def forecast_for_current_request(forecast, from_cache:)
      forecast.with_request_context(
        submitted_address: @address,
        from_cache: from_cache
      )
    end

    def cache_key(zip_code)
      "weather_forecast:#{zip_code}"
    end
  end
end
