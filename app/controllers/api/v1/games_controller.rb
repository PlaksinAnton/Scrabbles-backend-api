class Api::V1::GamesController < Api::V1::ApplicationController
  include Authentication
  include Validation
  before_action :authorize_request, except: [:index, :new_game, :join_game]
  before_action :validate_payload, except: [:index, :new_game, :join_game]

  def index
    generate_response(game: Game.all, plural: true)
  end

  #############
  def show
    generate_response(game: game)
  end

  def new_game
    game = Game.create
    game.add_player!(player_params[:nickname])

    set_token(game.created_player_id, game.id)
    generate_response(game: game, status_code: :created)
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return render json: { error: "Game not found!" }, status: :bad_request unless game

    begin
      game.add_player!(player_params[:nickname])
    rescue RuntimeError => e
      return render json: { error: e.message }, status: :bad_request
    end
    
    set_token(game.created_player_id, game.id)
    generate_response(game: game)
  end

  def start_game
    begin
      game.start!(current_player, configuration_params)
    rescue RuntimeError => e
      return render json: { error: e.message }, status: :bad_request
    end

    generate_response(game: game)
  end

  def submit_turn
    begin
      game.next_turn!(current_player, submit_params)
    # rescue AASM::InvalidTransition => e
    #   return render json: { error: e.message }, status: :method_not_allowed
    rescue RuntimeError => e
      return render json: { error: e.message }, status: :bad_request
    end

    game.end_game! if game.game_has_a_winner? && game.all_players_are_done? 
    
    generate_response(game: game)
  end

  def exchange
    begin
      game.exchange!(current_player, exchange_params)
    rescue RuntimeError => e
      return render json: { error: e.message }, status: :bad_request
    end

    game.end_game! if game.game_has_a_winner? && game.all_players_are_done?

    generate_response(game: game)
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

  private
  def generate_response(game:, plural: false, status_code: :ok)
    sym = plural ? :games : :game
    render json: {sym => game},
      except: [:created_at, :updated_at, :words],
      include: {players: {except: [:game_id, :created_at, :updated_at]}},
      status: status_code
  end

  def player_params
    res = [:nickname].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(:nickname)
  end

  def configuration_params
    res = [:language, :hand_size, :winnig_score].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(:language, :hand_size, :winnig_score)
  end

  def submit_params
    res = [:positions, :letters, :hand].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(positions: [], letters: [], hand: [])
  end

  def exchange_params
    res = [:letters, :hand].each_with_object(params) do |key, obj|
      obj.require(key)
    end
    res.permit(letters: [], hand: [])
  end
end
