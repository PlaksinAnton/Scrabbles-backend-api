module Authentication
  SECRET_KEY = Rails.application.secrets.secret_key_base
  ENCRIPTION_METHOD = 'HS256'
  attr_accessor :current_player

  def set_token(player_id, nickname)
    payload = { sub: player_id, nickname: nickname }
    token = JWT.encode payload, SECRET_KEY, ENCRIPTION_METHOD, header_fields={ typ: 'JWT' }
    response.set_header('Token', token)
    Rails.logger.info "Token set in 'Token' header"
  end

  def authorize_request
    token = request.headers['Authorization']
    begin
      decoded_token = JWT.decode token, SECRET_KEY, true, { algorithm: ENCRIPTION_METHOD }
    rescue JWT::DecodeError => e
      Rails.logger.warn "Bad token"
      return render json: { errors: e.message }, status: :unauthorized
    end

    self.current_player = Player.find_by(id: decoded_token.first['sub'])
    player_not_found unless self.current_player

    Rails.logger.info "Token verified"
  end

  private
  def player_not_found
    render json: { error: "Player not found!" }, status: :unauthorized
  end
end