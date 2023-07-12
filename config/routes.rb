require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"
  # root to: "transactions#index"

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end
  mount Sidekiq::Web => "/sidekiq1970"

  resources :users, only: [:update] do
    member do
      get :trigger
    end
  end

  resources :shops, only: [:index]
  get '/shops/cohort', to: 'shops#cohort'
  get '/shops/main_chart', to: 'shops#main_chart'

  resources :transactions, only: [:index]
  get '/transactions/main_chart', to: 'transactions#main_chart'

  get 'timeline', to: 'timeline#index'

  post '/stripe/webhook', to: 'stripe#webhook'
end
