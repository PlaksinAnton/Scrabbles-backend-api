class AddAasmStateToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :aasm_state, :string
  end
end
