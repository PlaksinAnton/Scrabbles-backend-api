class AddNicknameToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :nickname, :string
  end
end
