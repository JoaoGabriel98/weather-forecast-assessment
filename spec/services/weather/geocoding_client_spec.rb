# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::GeocodingClient do
  describe ".call" do
    it "returns latitude and longitude for a ZIP code" do
      stub_request(:get, "https://geocoding-api.open-meteo.com/v1/search")
        .with(query: hash_including("name" => "90210"))
        .to_return(
          status: 200,
          body: {
            results: [
              {
                latitude: 34.0901,
                longitude: -118.4065,
                name: "Beverly Hills",
                country: "United States"
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call("90210")

      expect(result).to be_success
      expect(result.value[:latitude]).to eq(34.0901)
      expect(result.value[:longitude]).to eq(-118.4065)
    end

    it "returns a failure when no location is found" do
      stub_request(:get, "https://geocoding-api.open-meteo.com/v1/search")
        .with(query: hash_including("name" => "00000"))
        .to_return(
          status: 200,
          body: { results: [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.call("00000")

      expect(result).to be_failure
      expect(result.error).to eq("Could not find a location for ZIP code 00000.")
    end

    it "returns a failure when the geocoding API responds with an error" do
      stub_request(:get, "https://geocoding-api.open-meteo.com/v1/search")
        .with(query: hash_including("name" => "90210"))
        .to_return(status: 500, body: "Server error")

      result = described_class.call("90210")

      expect(result).to be_failure
      expect(result.error).to eq("Could not resolve the ZIP code location. Please try again.")
    end
  end
end
