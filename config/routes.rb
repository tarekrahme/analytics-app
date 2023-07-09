Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"

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
end
