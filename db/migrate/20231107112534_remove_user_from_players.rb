class RemoveUserFromPlayers < ActiveRecord::Migration[7.0]
  def change
    remove_reference :players, :user, null: false, foreign_key: true
  end
end
