class CreateGame < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.integer :current_turn, null: false
      t.integer :players_turn, null: false
      t.string :game_state, null: false
      t.integer :winnig_score, null: false
      t.string :winners, null: false
      t.string :words, null: false
      t.string :field, null: false
      t.string :letter_bag
      t.string :language
      t.integer :hand_size

      t.timestamps
    end
  end
end
