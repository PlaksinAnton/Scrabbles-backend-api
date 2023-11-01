class Api::V1::UsersController < ApplicationController
  def index
    render json: User.all, status: 200
  end

  def show
    user = User.find_by(id: params[:id])
    return user_not_found unless user

    render json: user, status: 200
  end

  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: 200
    else
      render json: { error: "Creating Error!" }
      Rails.logger.error 'Failed to create User'
    end
  end

  def update
    ######
  end

  def destroy
    user = User.find_by(id: params[:id])
    return user_not_found unless user

    user.destroy
    render json: { ok: "User has been deleted!" }, status: 200
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    return render json: { error: "Game has already started!" } unless game.in_lobby?

    player_count = game.players.size
    return render json: { error: "Game is full!" } if player_count >= 4

    player = Player.create(game_id: game.id, user_id: user.id, turn_id: player_count)

    render_game(game)
  end

  def start_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    player = game.players.find{ |player| player.user_id == user.id }
    return player_not_found unless player

    return render json: { error: "Specified user must have a first turn to start the game!" } unless player.turn_id == 0

    return render json: { error: "Can't start the game" } unless game.start!

    render_game(game)
  end

  def submit_turn
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    player = game.players.find{ |player| player.user_id == user.id }
    return player_not_found unless player

    return render json: { error: "It is other player's turn" } unless player.turn_id == game.current_turn%game.players.size

    game.submited_data = params[:game]
    game.retry_turn! unless game.next_turn!

    render_game(game)
  end

  def leave_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    player = game.players.find{ |player| player.user_id == user.id }
    return player_not_found unless player

    player.destroy
    render json: { ok: "User left the game!" }, status: 200
  end

  private
  def user_params
    params.require(:user).permit(:nickname)
  end

  # def game_params
  #   params.require(:game)
  #     .permit(:id, 
  #             :field, 
  #             :letter_bag, 
  #             :current_turn, 
  #             :aasm_state, 
  #             :players:[           
  #             ])
  # end

  def user_not_found
    render json: { error: "User not found!" }
  end

  def game_not_found
    render json: { error: "Game not found!" }
  end

  def player_not_found
    render json: { error: "Specified user is not connected to the game!" }
  end

  def render_game(game)
    render json: {game: game},
      except: [:created_at, :updated_at],
      include: {players: {only: [:hand, :turn_id], methods: [:user_id, :nickname]}},
      status: 200
  end
end
