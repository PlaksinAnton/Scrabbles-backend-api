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
    set_token(player.id, game.id)

    render_game(game.reload)
  end

  def join_game
    game = Game.find_by(id: params[:game_id])
    return game_not_found unless game

    begin
      game.add_player!(params[:nickname])
    rescue Exception => e
      return render json: { error: e.message }
    end
    
    game.reload
    player_id = game.players.find_by(nickname: params[:nickname]).id
    set_token(player_id, game.id)

    render_game(game)
  end

  def start_game
    begin
      game.start!(current_player)
    rescue Exception => e
      return render json: { error: e.message }
    end

    render_game(game.reload)
  end

  def submit_turn
    game.submited_data = params[:game]

    begin
      game.next_turn!(current_player)
    rescue Exception => e
      game.retry_turn!
      return render json: { error: e.message }
    end

    render_game(game.reload)
  end

  def leave_game
    current_player.destroy
    render json: { success: "Player left the game!" }, status: 200
  end

  def destroy    
    game.destroy
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
