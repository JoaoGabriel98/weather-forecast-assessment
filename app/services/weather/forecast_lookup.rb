# frozen_string_literal: true

module Weather
  # Application Service that orchestrates the process of looking up a weather forecast for a given address.
  # We take care of the cache here
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

      if cached_forecast
        # The cached object is copied with an updated flag so the UI can tell the user
        # that this response did not trigger a new external API request.
        return ApplicationResult.success(cached_forecast.with_cache_status(true))
      end

      fresh_forecast_result = fetch_fresh_forecast(zip_code)
      return fresh_forecast_result if fresh_forecast_result.failure?

      Rails.cache.write(cache_key(zip_code), fresh_forecast_result.value, expires_in: CACHE_EXPIRATION)

      ApplicationResult.success(fresh_forecast_result.value.with_cache_status(false))
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

    def cache_key(zip_code)
      "weather_forecast:#{zip_code}"
    end
  end
end
