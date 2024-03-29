class Player < ApplicationRecord
  belongs_to :game
  before_create :set_defaults
  
  def set_defaults
    self.score = 0
    self.hand = '[]'
    self.active_player = true
    self.want_to_end = false
  end

  def hand
    JSON(super)
  end

  def vhand(id)
    if id == self.id
      JSON(hand)
    else
      'Don\'t peek ;)'
    end
  end
end
