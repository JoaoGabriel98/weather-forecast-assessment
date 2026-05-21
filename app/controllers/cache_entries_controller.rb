# frozen_string_literal: true

class CacheEntriesController < ApplicationController
  def index
    @entries = cache_entries
  end

  private

  def cache_entries
    data = Rails.cache.instance_variable_get(:@data)

    return [] unless data.respond_to?(:keys)

    data.keys.grep(/\Aweather_forecast:/).filter_map do |key|
      forecast = Rails.cache.read(key)
      next unless forecast

      expires_at = cache_entry_expires_at(data[key])

      {
        key: key,
        forecast: forecast,
        expires_at: expires_at,
        expires_at_iso: expires_at&.iso8601,
        expires_at_us: expires_at&.strftime("%m/%d/%Y %I:%M:%S %p")
      }
    end
  end

  def cache_entry_expires_at(entry)
    raw_expires_at =
      if entry.respond_to?(:expires_at) && entry.expires_at.present?
        entry.expires_at
      else
        entry.instance_variable_get(:@expires_at)
      end

    return normalize_time(raw_expires_at) if raw_expires_at.present?

    created_at = entry.instance_variable_get(:@created_at)
    expires_in = entry.instance_variable_get(:@expires_in)

    return unless created_at.present? && expires_in.present?

    normalize_time(created_at + expires_in)
  end

  def normalize_time(value)
    # Rails::Cache::Entry may expose expiration as a Float timestamp.
    # The browser countdown needs a real Time object so we can format it safely.
    return value.in_time_zone if value.respond_to?(:in_time_zone)

    Time.zone.at(value.to_f)
  end
end
