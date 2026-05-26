# frozen_string_literal: true

# Extracts and normalizes US ZIP codes from free-form address input.
class AddressZipExtractor
  ZIP_CODE_PATTERN = /\b\d{5}(?:-\d{4})?\b/

  def self.call(address)
    new(address).call
  end

  def initialize(address)
    @address = address.to_s
  end

  def call
    match = @address.match(ZIP_CODE_PATTERN)

    return nil unless match

    # ZIP+4 values are normalized to the base 5-digit ZIP because the forecast
    # requirement and cache key are ZIP-code based.
    match[0].split("-").first
  end
end
