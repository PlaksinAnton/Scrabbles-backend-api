module Validation

  private
  attr_accessor :current_player
  attr_accessor :game

  def validate_payload
    self.game = Game.find_by(id: self.payload['game'])
    game_not_found unless self.game
    self.current_player = self.game.players.find_by(id: self.payload['sub'])
    player_not_found unless self.current_player
  end

  def validate_player
    self.current_player = Player.find_by(id: self.payload['sub'])
    player_not_found unless self.current_player
  end

  def validate_game
    self.game = Game.find_by(id: self.payload['game'])
    game_not_found unless self.game
  end

  def game_not_found
    render json: { error: "Game not found!" }, status: :unauthorized
  end

  def player_not_found
    render json: { error: "Player not found!" }, status: :unauthorized
  end
end