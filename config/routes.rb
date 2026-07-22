Rails.application.routes.draw do
  root "homes#index"

  # API routes for React Native app
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh_token", to: "auth#refresh_token"
      get "auth/me", to: "auth#current_user"

      # Users
      resources :users, only: [ :show, :index, :update, :destroy ] do
        member do
          get :browse_profile
          delete :delete_gallery_photo
          post :upload_gallery_photo
        end
        collection do
          get :search
          get :suggestions
        end
      end

      # User Interactions
      resources :user_interactions, only: [ :create ] do
        member do
          post :accept
          post :decline
        end
        collection do
          get :sent
          get :received
          get :shortlist
        end
      end
    end
  end

  # Language switching - allow both GET and POST
  match "set_locale", to: "application#set_locale_preference", as: "set_locale", via: [ :get, :post ]

  resources :users, only: [ :show, :index, :new, :create, :edit, :update, :destroy ] do
    collection do
      get :import_pdf
      post :process_pdf
      get :import_image
      post :process_image
      get :browse
      get :skipped
    end
    member do
      delete :delete_gallery_photo
      get :browse_profile
    end
  end

  # User interactions member routes with explicit path helpers (for browse_profile)
  post "/users/:id/express_interest", to: "user_interactions#express_interest", as: "user_express_interest"
  post "/users/:id/shortlist", to: "user_interactions#shortlist", as: "user_shortlist"
  post "/users/:id/add_notes", to: "user_interactions#add_notes", as: "user_add_notes"
  post "/users/:id/reject", to: "user_interactions#reject", as: "user_reject"

  # User interactions routes
  get "my-interests", to: "user_interactions#sent_interests", as: "sent_interests"
  get "received-interests", to: "user_interactions#received_interests", as: "received_interests"
  get "shortlist", to: "user_interactions#shortlisted", as: "shortlisted"

  resources :user_interactions, only: [] do
    member do
      post :accept_interest
      post :decline_interest
    end
  end
  get "dashboard", to: "users#dashboard", as: "user_dashboard"

  resources :sessions, only: [ :new, :create, :destroy ]

  get "login", to: "sessions#new"

  # Multi-step signup/onboarding
  get "signup", to: "signups#new", as: "new_signup"
  post "signup", to: "signups#create", as: "signups"
  get "signup/step/:step", to: "signups#show", as: "signup_step"
  patch "signup/step/:step", to: "signups#update"
  delete "logout", to: "sessions#destroy"

  # OAuth routes
  get "auth/google_oauth2/callback", to: "sessions#google_callback"
  get "auth/facebook/callback", to: "sessions#facebook_callback"
  get "auth/failure", to: "sessions#auth_failure"
  match "auth/:provider/callback", to: "sessions#auth_callback", via: [ :get, :post ]

  # Admin routes
  scope path: "admin", as: "admin" do
    get "dashboard", to: "admin#dashboard", as: "dashboard"
    get "users", to: "admin#users", as: "users"
    get "users/new", to: "admin#new", as: "new_user"
    post "users", to: "admin#create"
    get "users/:id", to: "admin#show", as: "user"
    get "users/:id/edit", to: "admin#edit", as: "edit_user"
    patch "users/:id", to: "admin#update"
    put "users/:id", to: "admin#update"
    delete "users/:id", to: "admin#destroy"
    delete "users/:id/gallery_photo", to: "admin#delete_gallery_photo", as: "delete_gallery_photo_user"
    get "users/:id/delete", to: "admin#delete", as: "delete_user"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
