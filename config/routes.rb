Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show, :create, :update, :destroy]
      put 'users/:user_id/connect_to_game/:game_id', to: 'users#connect_to_game'
      put 'users/:user_id/leave_game/:game_id', to: 'users#leave_game'
      put 'users/:user_id/start_game/:game_id', to: 'users#start_game'
      put 'users/:user_id/submit_turn/:game_id', to: 'users#submit_turn'      
      
      resources :games, only: [:index, :show, :create, :update, :destroy]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
