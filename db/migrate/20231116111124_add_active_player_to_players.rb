class AddActivePlayerToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :active_player, :boolean, null: false
  end
end
