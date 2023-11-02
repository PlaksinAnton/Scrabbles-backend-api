class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game

  def nickname
    user.nickname
  end

  def user_id
    user.id
  end

  def hand_array
    JSON(self.hand)
  end
end
