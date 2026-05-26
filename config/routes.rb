Rails.application.routes.draw do
  root "forecasts#new"

  resource :forecast, only: %i[new create]
end
