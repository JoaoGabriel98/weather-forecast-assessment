# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::WeatherCodeMapper do
  describe ".call" do
    it "returns a known description" do
      expect(described_class.call(0)).to eq("Clear sky")
    end

    it "returns Unknown for unmapped codes" do
      expect(described_class.call(999)).to eq("Unknown")
    end
  end
end
