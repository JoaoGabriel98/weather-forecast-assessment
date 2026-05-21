# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddressZipExtractor do
  describe ".call" do
    it "extracts a 5-digit ZIP code from an address" do
      expect(described_class.call("Beverly Hills, CA 90210")).to eq("90210")
    end

    it "normalizes ZIP+4 to the base ZIP code" do
      expect(described_class.call("Washington, DC 20500-0003")).to eq("20500")
    end

    it "returns nil when no ZIP code is present" do
      expect(described_class.call("No ZIP here")).to be_nil
    end
  end
end
