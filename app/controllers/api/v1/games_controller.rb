class Api::V1::GamesController < ApplicationController
  def index
    render json: {games: Game.all}, 
      except: [:created_at, :updated_at],
      include: {players: {only: [:id, :hand, :turn_id], methods: :nickname}},
      status: 200
  end

  def show
    game = Game.find_by(id: params[:id])
    binding.pry
    if game
      render json: {game: game},
        except: [:created_at, :updated_at],
        include: {players: {only: [:id, :hand, :turn_id], methods: :nickname}},
        status: 200
    else
      render json: game_not_found
    end
  end 

  def create
    game = Game.create()
    render json: game, status: 200
  end

  def update
  end

  def destroy
  end

  private
  def game_not_found
    { error: "Game not found!" }
  end
end
