class Player < ApplicationRecord
  belongs_to :game

  def hand_array
    JSON(self.hand)
  end
end
