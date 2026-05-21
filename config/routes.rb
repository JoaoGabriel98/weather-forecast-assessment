Rails.application.routes.draw do
  root "forecasts#new"

  resource :forecast, only: %i[new create]

  if Rails.env.development?
    get "/cache", to: "cache_entries#index"
  end
end
