FactoryBot.define do
  factory :game do
    transient do
      players_count { 1 }
    end
    after(:create) do |full_game, evaluator|
      create_list(:player, evaluator.players_count, game: full_game)
      # full_game.reload
    end
  end

  factory :active_game, parent: :game do
    transient do
      players_count { 2 }
      hand_size { 7 }
      winning_score { 150 }
    end
    after(:create) do |game, evaluator|
      game.start!(game.players.first, { 
        language: 'rus', 
        hand_size: evaluator.hand_size,
        winning_score: evaluator.winning_score,
      })
    end 
  end

  factory :active_game_with_word, parent: :active_game do
    transient do
      word { ['в','а','з','а'] }
    end
    after(:create) do |game, evaluator|
      new_field = game.field
      new_field[112..115] = evaluator.word
      game.field = JSON(new_field)
      game.save
    end 
  end
end
