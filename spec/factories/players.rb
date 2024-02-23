FactoryBot.define do
  factory :player do
    sequence(:nickname) { |n| "Biba_#{n}" }
    game_id { 58008 }
    game
  end
end
