module Authentication
  SECRET_KEY = Rails.application.secret_key_base
  ENCRIPTION_METHOD = 'HS256'

  def self.generate_token(player_id, game_id)
    new_payload = { sub: player_id, game: game_id, exp: 24.hours.from_now.to_i }
    JWT.encode new_payload, SECRET_KEY, ENCRIPTION_METHOD, header_fields={ typ: 'JWT' }
  end

  def self.decode_token(token)
    JWT.decode token, SECRET_KEY, true, { algorithm: ENCRIPTION_METHOD }
  end

  private
  attr_accessor :payload

  def set_token(player_id, game_id)
    response.set_header('Token', Authentication.generate_token(player_id, game_id))
    Rails.logger.info "Token is set in the 'Token' header"
  end

  def authorize_request
    begin
      decoded_token = Authentication.decode_token(request.headers['Authorization'])
      self.payload = decoded_token.first
    rescue JWT::DecodeError => e
      Rails.logger.warn "Authentication failed: bad token"
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end