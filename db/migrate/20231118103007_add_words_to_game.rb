class AddWordsToGame < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :words, :string
  end
end
