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
    render json: { error: "User has been deleted!" }
  end

  def connect_to_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    return render json: { error: "Game has already started!" } unless game.in_lobby?

    player = Player.create(game_id: game.id, user_id: user.id, turn_id: game.players.size)
    render json: player, status: 200
  end

  def start_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    player = game.players.find{ |player| player.user_id == user.id }
    return player_not_found unless player

    return render json: { error: "Specified user should have a first turn to start the game!" } unless player.turn_id == 0

    return render json: { error: 'Not enough players to start game!' } unless game.start!

    render json: {game: game},
    except: [:created_at, :updated_at],
    include: {players: {only: [:id, :hand, :turn_id], methods: :nickname}},
    status: 200
  end

  def submit_turn
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    player = game.players.find{ |player| player.user_id == user.id }
    return player_not_found unless player

    return render json: { error: "It is other's player turn" } unless player.turn_id == game.current_turn

    game.submited_data = params[:game]
    game.retry_turn! unless game.next_turn!
    render json: {game: game},
        except: [:created_at, :updated_at],
        include: {players: {only: [:id, :hand, :turn_id], methods: :nickname}},
        status: 200
  end

  def leave_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    user = User.find_by(id: params[:user_id])
    return user_not_found unless user

    player = game.players.find{ |player| player.user_id == user.id }
    return player_not_found unless player

    player.destroy
    render json: { error: "User left the game!" }
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
end
