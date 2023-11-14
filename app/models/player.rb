class Player < ApplicationRecord
  belongs_to :game

  def hand
    JSON(super)
  end
end
