# frozen_string_literal: true

class ApplicationResult
  attr_reader :value, :error

  # Cleaner way to construct success and failure results without needing to know the internal structure of the class.
  def self.success(value)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  def initialize(success:, value: nil, error: nil)
    @success = success
    @value = value
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !success?
  end
end
