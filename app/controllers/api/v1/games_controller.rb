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

    render_game(game)
  end

  def update
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

  def render_game(game, plural = false)
    sym = plural ? :games : :game
    render json: {sym => game},
      except: [:created_at, :updated_at, :field, :letter_bag], methods: [:field_array, :bag_array],
      include: {players: {only: [:turn_id], methods: [:user_id, :nickname, :hand_array]}},
      status: 200
  end
end
