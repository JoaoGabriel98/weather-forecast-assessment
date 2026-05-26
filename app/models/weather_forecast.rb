# frozen_string_literal: true

class WeatherForecast
  attr_reader :submitted_address,
              :zip_code,
              :current_temperature,
              :high_temperature,
              :low_temperature,
              :description,
              :from_cache

  def initialize(
    submitted_address:,
    zip_code:,
    current_temperature:,
    high_temperature:,
    low_temperature:,
    description:,
    from_cache:
  )
    @submitted_address = submitted_address
    @zip_code = zip_code
    @current_temperature = current_temperature
    @high_temperature = high_temperature
    @low_temperature = low_temperature
    @description = description
    @from_cache = from_cache
  end

  def from_cache?
    from_cache
  end

  def with_request_context(submitted_address:, from_cache:)
    self.class.new(
      submitted_address: submitted_address,
      zip_code: zip_code,
      current_temperature: current_temperature,
      high_temperature: high_temperature,
      low_temperature: low_temperature,
      description: description,
      from_cache: from_cache
    )
  end
end
