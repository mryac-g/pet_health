Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  devise_scope :user do
    post "users/guest_sign_in", to: "users/sessions#guest", as: :guest_sign_in
  end

  resources :meal_types, only: %i[index create destroy]
  resources :meal_units, only: %i[index create destroy]
  resources :medicine_types, only: %i[index create destroy]
  resources :hospital_names, only: %i[index create destroy]
  resources :vaccine_types, only: %i[index create destroy]

  resources :pets, only: %i[new create show edit update] do
    resources :care_records, only: %i[index show new create edit update destroy] do
      resources :attachments, only: %i[create destroy]
    end

    member do
      get :summary
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
