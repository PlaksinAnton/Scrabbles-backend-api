Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :games, only: [:index, :show, :destroy]
      post 'new_game', to: 'games#create' # {"nickname": "Boba"}
      post 'join_game/:game_id', to: 'games#join_game' # {"nickname": "Biba"}
      post 'start_game/:game_id', to: 'games#start_game'
      post 'submit_turn/:game_id', to: 'games#submit_turn'   
      post 'leave_game/:game_id', to: 'games#leave_game'
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
