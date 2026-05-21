# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ForecastClient do
  describe ".call" do
    it "returns a normalized forecast" do
      stub_request(:get, "https://api.open-meteo.com/v1/forecast")
        .with(query: hash_including("latitude" => "34.0901", "longitude" => "-118.4065"))
        .to_return(
          status: 200,
          body: {
            current: {
              temperature_2m: 72.4,
              weather_code: 0
            },
            daily: {
              temperature_2m_max: [ 81.2 ],
              temperature_2m_min: [ 63.8 ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call(
        zip_code: "90210",
        submitted_address: "Beverly Hills, CA 90210",
        latitude: 34.0901,
        longitude: -118.4065
      )

      expect(result).to be_success

      forecast = result.value

      expect(forecast.zip_code).to eq("90210")
      expect(forecast.current_temperature).to eq(72.4)
      expect(forecast.high_temperature).to eq(81.2)
      expect(forecast.low_temperature).to eq(63.8)
      expect(forecast.description).to eq("Clear sky")
      expect(forecast).not_to be_from_cache
    end
  end
end
