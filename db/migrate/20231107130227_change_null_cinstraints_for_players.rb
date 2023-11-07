class ChangeNullCinstraintsForPlayers < ActiveRecord::Migration[7.0]
  def change
    change_column_null :players, :turn_id, false
    change_column_null :players, :nickname, false
  end
end
