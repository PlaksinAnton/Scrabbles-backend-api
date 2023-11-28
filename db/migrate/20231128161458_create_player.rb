class CreatePlayer < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      t.string :nickname, null: false
      t.integer :score, null: false
      t.boolean :active_player, null: false
      t.string :hand, null: false
      t.references :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end
