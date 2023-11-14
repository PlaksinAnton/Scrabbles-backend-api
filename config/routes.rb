Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :games, only: [:index, :destroy]
      post 'new_game', to: 'games#new_game' # {"nickname": "Boba"}
      post 'join_game/:game_id', to: 'games#join_game' # {"nickname": "Biba"}
      post 'start_game', to: 'games#start_game'
      post 'submitt_turn', to: 'games#submitt_turn'
      post 'exchange', to: 'games#exchange'
      post 'leave_game', to: 'games#leave_game'
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
