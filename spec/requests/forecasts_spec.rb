# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  describe "GET /" do
    it "renders the forecast form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weather Forecast")
    end
  end

  describe "POST /forecast" do
    it "renders the forecast result when lookup succeeds" do
      forecast = WeatherForecast.new(
        submitted_address: "Beverly Hills, CA 90210",
        zip_code: "90210",
        current_temperature: 72.4,
        high_temperature: 81.2,
        low_temperature: 63.8,
        description: "Clear sky",
        from_cache: false
      )

      allow(Weather::ForecastLookup).to receive(:call)
        .with(address: "Beverly Hills, CA 90210")
        .and_return(ApplicationResult.success(forecast))

      post forecast_path, params: {
        forecast: {
          address: "Beverly Hills, CA 90210"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("90210")
      expect(response.body).to include("Fresh API response")
    end

    it "renders validation error when lookup fails" do
      allow(Weather::ForecastLookup).to receive(:call)
        .with(address: "Invalid address")
        .and_return(ApplicationResult.failure("Please include a valid US ZIP code in the address."))

      post forecast_path, params: {
        forecast: {
          address: "Invalid address"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please include a valid US ZIP code in the address.")
    end
  end
end
