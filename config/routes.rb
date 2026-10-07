Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  root to: "pages#home"

  get "/tournaments", to: "player_tournaments#index", as: :player_tournaments

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.


  get "up" => "rails/health#show", as: :rails_health_check
  get "/access", to: "onboarding#access", as: :access
  get "/onboarding/profile", to: "profiles#edit", as: :onboarding_profile
  patch "/onboarding/profile", to: "profiles#onboarding_update"
  resource :profile, only: %i[show update], controller: "profiles"
  get "/club_subscriptions/quote", to: "club_subscriptions#quote", as: :club_subscription_quote
  resources :club_subscriptions, only: %i[index new create]
  resources :clubs, except: :destroy do
    resource :subscription_change,
             only: %i[new create destroy],
             controller: "subscription_changes"

    resources :tournaments, only: %i[index show new create edit update destroy] do
      member do
        patch :finish
        patch :join
      end

      resource :invite_link,
               only: :show,
               controller: "tournament_invite_links"

      resource :clock,
               only: :show,
               controller: "tournament_clocks" do
        post :start
        patch :pause
        patch :resume
        patch :advance
        get :state
      end

      resource :charge_options,
               only: %i[new create edit update],
               controller: "tournament_charge_options"
      resource :prize_pool,
               only: %i[new create edit update],
               controller: "tournament_prize_pools"
      resources :blind_levels, only: %i[new create]
      resources :registrations,
                only: :index,
                controller: "tournament_registrations"
      resources :transactions,
                only: :index,
                controller: "tournament_transactions" do
        member do
          patch :confirm
        end
      end
      resources :recharges,
                only: %i[index create],
                controller: "tournament_recharges"
      post :buy_in_payment,
           to: "tournament_buy_in_payments#create"
    end
  end

  post "/webhooks/asaas", to: "webhooks/asaas#create", as: :asaas_webhook

  patch "tournament-invitations/:token/confirm",
        to: "tournament_invitation_links#confirm",
        as: :confirm_tournament_invitation
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
