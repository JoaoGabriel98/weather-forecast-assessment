# frozen_string_literal: true

class ForecastsController < ApplicationController
  def new
  end

  def create
    result = Weather::ForecastLookup.call(address: forecast_params[:address])

    if result.success?
      @forecast = result.value
      render :show, status: :ok
    else
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def forecast_params
    params.require(:forecast).permit(:address)
  end
end
