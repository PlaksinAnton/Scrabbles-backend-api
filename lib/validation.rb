module Validation

  private
  attr_accessor :current_player, :game

  def validate_payload
    self.game = Game.find_by(id: self.payload['game'])
    return game_not_found unless self.game
    self.current_player = self.game.players.find_by(id: self.payload['sub'])
    return player_not_found unless self.current_player
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
    render json: { error: "Bad token. Game not found!" }, status: :unauthorized
  end

  def player_not_found
    render json: { error: "Bad token. Player not found!" }, status: :unauthorized
  end
end