Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.


  get "up" => "rails/health#show", as: :rails_health_check
  get "/access", to: "onboarding#access", as: :access
  resources :clubs do
    resources :tournaments, only: %i[index new create edit update destroy] do
      resource :clock,
               only: :show,
               controller: "tournament_clocks" do
        post :start
        patch :pause
        patch :resume
      end

      resource :charge_options,
               only: %i[new create edit update],
               controller: "tournament_charge_options"
      resources :blind_levels, only: %i[new create]
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
