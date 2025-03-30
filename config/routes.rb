Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  resources :email_servers, only: [ :create ] do
    post :buy_domain, on: :collection
    post :setup_mail_records, on: :collection
  end
  resources :email_accounts, only: [ :create, :index ] do
    get :mail_server_status, on: :collection
  end
end
