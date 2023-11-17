class RemoveTurnIdFromPlayers < ActiveRecord::Migration[7.0]
  def change
    remove_column :players, :turn_id, :integer
  end
end
