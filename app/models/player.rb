class Player < ApplicationRecord
  belongs_to :game
  before_create :set_defaults
  
  def set_defaults
    self.active_player = true
    self.score = 0
    self.hand = '[]'
  end

  def hand
    JSON(super)
  end
end
