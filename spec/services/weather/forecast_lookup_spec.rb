# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ForecastLookup do
  before do
    Rails.cache.clear
  end

  describe ".call" do
    it "returns a failure when address is blank" do
      result = described_class.call(address: "")

      expect(result).to be_failure
      expect(result.error).to eq("Please enter an address.")
    end

    it "returns a failure when address does not contain a ZIP code" do
      result = described_class.call(address: "Beverly Hills, CA")

      expect(result).to be_failure
      expect(result.error).to eq("Please include a valid US ZIP code in the address.")
    end

    it "fetches a fresh forecast and stores it in cache" do
      allow(Weather::GeocodingClient).to receive(:call)
        .with("90210")
        .and_return(ApplicationResult.success({ latitude: 34.0901, longitude: -118.4065 }))

      allow(Weather::ForecastClient).to receive(:call)
        .with(zip_code: "90210",
              submitted_address: "Beverly Hills, CA 90210",
              latitude: 34.0901,
              longitude: -118.4065)
        .and_return(ApplicationResult.success(build_forecast(from_cache: false)))

      result = described_class.call(address: "Beverly Hills, CA 90210")

      expect(result).to be_success
      expect(result.value.zip_code).to eq("90210")
      expect(result.value).not_to be_from_cache
      expect(Rails.cache.read("weather_forecast:90210")).to be_present
    end

    it "returns cached forecast for subsequent requests by ZIP code" do
      Rails.cache.write(
        "weather_forecast:90210",
        build_forecast(from_cache: false),
        expires_in: described_class::CACHE_EXPIRATION
      )

      result = described_class.call(address: "Another address, CA 90210")

      expect(result).to be_success
      expect(result.value).to be_from_cache
    end

    it "does not call external clients when forecast is cached" do
      Rails.cache.write(
        "weather_forecast:90210",
        build_forecast(from_cache: false),
        expires_in: described_class::CACHE_EXPIRATION
      )

      allow(Weather::GeocodingClient).to receive(:call)
      allow(Weather::ForecastClient).to receive(:call)

      described_class.call(address: "Beverly Hills, CA 90210")

      expect(Weather::GeocodingClient).not_to have_received(:call)
      expect(Weather::ForecastClient).not_to have_received(:call)
    end
  end

  def build_forecast(from_cache:)
    WeatherForecast.new(
      submitted_address: "Beverly Hills, CA 90210",
      zip_code: "90210",
      current_temperature: 72.4,
      high_temperature: 81.2,
      low_temperature: 63.8,
      description: "Clear sky",
      from_cache: false
    )
  end
end
