class Api::V1::GamesController < Api::V1::ApplicationController
  include Authentication
  include Validation
  before_action :authorize_request, except: [:index, :new_game, :join_game]
  before_action :validate_payload, except: [:index, :new_game, :join_game]
  before_action :validate_nickname, only: [:new_game, :join_game]

  def index
    render_game(Game.all, true)
  end

  #############
  def new_game
    game = Game.create()

    player = Player.create(game_id: game.id, nickname: params[:nickname], turn_id: 0)
    set_token(player)

    render_game(game.reload)
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    return render json: { error: "Game has already started!" } unless game.in_lobby?

    player_count = game.players.size
    return render json: { error: "Game is full!" } if player_count >= 4

    player = Player.create(game_id: game.id, nickname: params[:nickname], turn_id: player_count)
    set_token(player)

    render_game(game.reload)
  end

  def start_game
    return render json: { error: "Specified player must have a first turn to start the game!" } unless current_player.turn_id == 0

    return render json: { error: "Can't start the game" } unless current_game.start!
    
    render_game(current_game.reload)
  end

  def submit_turn
    unless current_player.turn_id == current_game.current_turn % current_game.players.size
      return render json: { error: "It is other player's turn" }
    end

    current_game.submited_data = params[:game]
    current_game.retry_turn! unless current_game.next_turn!

    render_game(current_game.reload)
  end

  def leave_game
    current_player.destroy
    render json: { success: "Player left the game!" }, status: 200
  end

  def destroy    
    current_game.destroy
    render json: { success: "Game deleted!" }, status: 200
  end

  private
  def render_game(game, plural = false)
    sym = plural ? :games : :game
    render json: {sym => game},
      except: [:created_at, :updated_at, :field, :letter_bag], methods: [:field_array, :bag_array],
      include: {players: {only: [:id, :nickname, :turn_id], methods: [:hand_array]}},
      status: 200
  end

  def validate_nickname
    render json: { error: "Empty nickname!" } if params[:nickname].blank?
  end
end
