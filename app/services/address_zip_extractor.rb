# frozen_string_literal: true

# Created for just deal with parsing
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

    # We normalize ZIP+4 values to the base 5-digit ZIP because the forecast
    # requirement is based on ZIP code and the cache should group equivalent requests.
    match[0].split("-").first
  end
end
