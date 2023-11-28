class Api::V1::GamesController < Api::V1::ApplicationController
  include Authentication
  include Validation
  before_action :authorize_request, except: [:index, :new_game, :join_game]
  before_action :validate_payload, except: [:index, :new_game, :join_game]

  def index
    render_game(Game.all, true)
  end

  #############
  def new_game
    game = Game.create
    game.add_player!(params[:nickname])

    set_token(game.created_player_id, game.id)
    render_game(game)
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    begin
      game.add_player!(params[:nickname])
    rescue RuntimeError => e
      return render json: { error: e.message }
    end
    
    set_token(game.created_player_id, game.id)
    render_game(game)
  end

  def start_game
    begin
      game.start!(current_player)
    rescue RuntimeError => e
      return render json: { error: e.message }
    end

    render_game(game)
  end

  def submit_turn
    game.submitted_data = params

    begin
      game.next_turn!(current_player)
    rescue RuntimeError => e
      return render json: { error: e.message }
    end

    render_game(game)
  end

  def exchange
    game.submitted_data = params

    begin
      game.exchange!(current_player)
    rescue RuntimeError => e
      return render json: { error: e.message }
    end

    render_game(game)
  end

  def leave_game
    current_player.update(active_player: false)
    render json: { success: "Player left the game!" }, status: 200
  end

  def destroy    
    game.destroy!(current_player)
    render json: { success: "Game deleted!" }, status: 200
  end

  private
  def render_game(game, plural = false)
    sym = plural ? :games : :game
    render json: {sym => game},
      except: [:created_at, :updated_at, :words],
      include: {players: {except: [:game_id, :created_at, :updated_at]}},
      status: 200
  end
end
