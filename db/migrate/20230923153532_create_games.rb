class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.text :field
      t.text :letter_bag
      t.integer :current_turn

      t.timestamps
    end
  end
end
