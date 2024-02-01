class Api::V1::GamesController < Api::V1::ApplicationController
  include Authentication
  include Validation
  before_action :authorize_request, except: [:index, :new_game, :join_game, :spelling_check]
  before_action :validate_payload, except: [:index, :new_game, :join_game, :spelling_check]
  rescue_from RuntimeError, ActionController::ParameterMissing, with: :render_bad_request
  rescue_from AASM::InvalidTransition, with: :render_method_not_allowed

  def index
    render_response(game: Game.all, plural: true)
  end

  #############
  def show
    render_response(game: game)
  end

  def new_game
    game = Game.create
    game.add_player!(player_params[:nickname])

    set_token(game.created_player_id, game.id)
    render_response(game: game, status_code: :created)
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return render json: { error: "Game not found!" }, status: :bad_request unless game

    game.add_player!(player_params[:nickname])
    set_token(game.created_player_id, game.id)
    render_response(game: game)
  end

  def start_game
    game.start!(current_player, configuration_params)
    render_response(game: game)
  end

  def submit_turn
    game.next_turn!(current_player, submit_params)
    game.end_game! if game.game_has_a_winner? && game.all_players_are_done? 
    render_response(game: game)
  end

  def exchange
    game.exchange!(current_player, exchange_params)
    game.end_game! if game.game_has_a_winner? && game.all_players_are_done?
    render_response(game: game)
  end

  def skip_turn
    game.skip_turn!(current_player)
    game.end_game! if game.game_has_a_winner? && game.all_players_are_done?
    render_response(game: game)
  end

  def leave_game
    current_player.update(active_player: false)
    game.reload
    if game.no_active_players?
      game.destroy
      return render json: { success: "Last player left the game, game deleted!" }
    end

    render json: { success: "Player left the game!" }
  end

  def spelling_check
    if Game.correct_wrod_spelling?(spelling_params[:word])
      render json: { correct_spelling: true }
    else
      render json: { correct_spelling: false }
    end
  end

  private
  def render_response(game:, plural: false, status_code: :ok)
    sym = plural ? :games : :game
    curr_id = current_player&.id
    render json: {sym => game},
      except: [:created_at, :updated_at, :words],
      include: {players: {except: [:game_id, :created_at, :updated_at], custom_methods: {hide_hands: curr_id}}},
      status: status_code
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def render_method_not_allowed(exception)
    render json: { error: exception.message }, status: :method_not_allowed
  end

  def player_params
    res = [:nickname].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(:nickname)
  end

  def configuration_params
    res = [:language].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(:language, :hand_size, :winning_score)
  end

  def submit_params
    res = [:positions, :letters].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(positions: [], letters: [], hand: [])
  end

  def exchange_params
    res = [:exchange_letters].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(exchange_letters: [], hand: [])
  end

  def spelling_params
    res = [:word].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(:word)
  end
end
