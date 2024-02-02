Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api/docs'
  mount Rswag::Api::Engine => '/api/docs'
  namespace :api do
    namespace :v1 do
      get 'show', to: 'games#show'
      get 'status', to: 'games#show'
      get 'quick_status', to: 'games#quick_status'
      post 'new_game', to: 'games#new_game'
      post 'join_game/:game_id', to: 'games#join_game'
      post 'start_game', to: 'games#start_game'
      post 'submit_turn', to: 'games#submit_turn'
      post 'exchange', to: 'games#exchange'
      post 'skip_turn', to: 'games#skip_turn'
      post 'leave_game', to: 'games#leave_game'
      post 'suggest_finishing', to: 'games#suggest_finishing'
      post 'spelling_check', to: 'games#spelling_check'
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end
