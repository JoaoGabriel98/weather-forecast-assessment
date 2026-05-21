# frozen_string_literal: true

module Weather
  class WeatherCodeMapper
    DESCRIPTIONS = {
      0 => "Clear sky",
      1 => "Mainly clear",
      2 => "Partly cloudy",
      3 => "Overcast",
      45 => "Fog",
      48 => "Depositing rime fog",
      51 => "Light drizzle",
      53 => "Moderate drizzle",
      55 => "Dense drizzle",
      61 => "Slight rain",
      63 => "Moderate rain",
      65 => "Heavy rain",
      71 => "Slight snow",
      73 => "Moderate snow",
      75 => "Heavy snow",
      80 => "Slight rain showers",
      81 => "Moderate rain showers",
      82 => "Violent rain showers",
      95 => "Thunderstorm"
    }.freeze

    def self.call(code)
      DESCRIPTIONS.fetch(code.to_i, "Unknown")
    end
  end
end
