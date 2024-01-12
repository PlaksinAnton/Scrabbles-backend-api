module Authentication
  SECRET_KEY = Rails.application.secret_key_base # Rails.application.secrets.secret_key_base
  ENCRIPTION_METHOD = 'HS256'

  private
  attr_accessor :payload

  def set_token(player_id, game_id)
    new_payload = { sub: player_id, game: game_id, exp: 24.hours.from_now.to_i }
    token = JWT.encode new_payload, SECRET_KEY, ENCRIPTION_METHOD, header_fields={ typ: 'JWT' }
    response.set_header('Token', token)
    Rails.logger.info "Token is set in the 'Token' header"
  end

  def authorize_request
    token = request.headers['Authorization']
    begin
      decoded_token = JWT.decode token, SECRET_KEY, true, { algorithm: ENCRIPTION_METHOD }
      self.payload = decoded_token.first
    rescue JWT::DecodeError => e
      Rails.logger.warn "Authentication failed: bad token"
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end