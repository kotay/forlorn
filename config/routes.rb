Sirport::Application.routes.draw do
  resources :gentlemen do
    member do
      match :run
      delete :remove_events
    end

    collection do
      post :propagate
      get :type_details
      get :event_descriptions
      get :diagram
    end
  end
  resources :events, :only => [:index, :show, :destroy]
  match "/worker_status" => "worker_status#show"

  post "/users/:user_id/update_location/:secret" => "user_location_updates#create"
  match "/users/:user_id/webhooks/:gentleman_id/:secret" => "webhooks#create"

  # mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'
  match "/delayed_job" => DelayedJobWeb, :anchor => false
  devise_for :users, :sign_out_via => [ :post, :delete ]

  match "/about" => "home#about"
  root :to => "home#index"
  match "/post" => "home#about"
end
