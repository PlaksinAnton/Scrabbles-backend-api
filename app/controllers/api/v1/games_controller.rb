class Api::V1::GamesController < ApplicationController
  def index
    render_game(Game.all, true)
  end

  def show
    game = Game.find_by(id: params[:id])
    return game_not_found unless game

    render_game(game)
  end 

  def create
    game = Game.create()

    player = Player.create(game_id: game.id, nickname: params[:nickname], turn_id: 0)

    render_game(game)
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    return render json: { error: "Empty nickname!" } if params[:nickname].blank?

    return render json: { error: "Game has already started!" } unless game.in_lobby?

    player_count = game.players.size
    return render json: { error: "Game is full!" } if player_count >= 4

    player = Player.create(game_id: game.id, nickname: params[:nickname], turn_id: player_count)

    render_game(game.reload)
  end

  def start_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    player = game.players.find_by(id: params[:player_id]) ##
    return player_not_found unless player

    return render json: { error: "Specified player must have a first turn to start the game!" } unless player.turn_id == 0

    return render json: { error: "Can't start the game" } unless game.start!

    render_game(game.reload)
  end

  def submit_turn
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    player = game.players.find_by(id: params[:player_id]) ##
    return player_not_found unless player

    return render json: { error: "It is other player's turn" } unless player.turn_id == game.current_turn%game.players.size

    game.submited_data = params[:game]
    game.retry_turn! unless game.next_turn!

    render_game(game.reload)
  end

  def leave_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    player = game.players.find_by(id: params[:player_id]) ##
    return player_not_found unless player

    player.destroy
    render json: { ok: "Player left the game!" }, status: 200
  end

  def destroy
    game = Game.find_by(id: params[:id])
    return game_not_found unless game
    
    game.destroy
    render json: {ok: "Game deleted!"}, status: 200
  end

  private
  def game_not_found
    render json: { error: "Game not found!" }
  end

  def player_not_found
    render json: { error: "Specified player is not connected to the game!" }
  end

  def render_game(game, plural = false)
    sym = plural ? :games : :game
    render json: {sym => game},
      except: [:created_at, :updated_at, :field, :letter_bag], methods: [:field_array, :bag_array],
      include: {players: {only: [:id, :nickname, :turn_id], methods: [:hand_array]}},
      status: 200
  end
end
