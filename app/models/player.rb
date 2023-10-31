class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game

  def nickname
    user.nickname
  end
end
