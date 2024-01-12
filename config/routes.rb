Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  namespace :api do
    namespace :v1 do
      resources :games, only: [:index]
      get 'show', to: 'games#show' # Token
      post 'new_game', to: 'games#new_game' # {"nickname": "Boba"}
      post 'join_game/:game_id', to: 'games#join_game' # {"nickname": "Biba"}
      post 'start_game', to: 'games#start_game' # Token
      post 'submit_turn', to: 'games#submit_turn' # Token
      post 'exchange', to: 'games#exchange' # Token
      post 'leave_game', to: 'games#leave_game' # Token
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
