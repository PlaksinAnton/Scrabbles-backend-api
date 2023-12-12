require 'swagger_helper'

RSpec.describe 'api/v1/games', type: :request do

  let!(:first_game) { first_game = create(:game); first_game.add_player!('kek'); first_game }
  let!(:Authorization) { new_payload = { sub: first_game.players.first.id,
                                        game: first_game.id, 
                                        exp: 24.hours.from_now.to_i,
                                      }
                        JWT.encode new_payload, 
                                    Rails.application.secrets.secret_key_base, 
                                    'HS256',
                                    header_fields={ typ: 'JWT' }
                      }
  path '/api/v1/new_game' do
    post('Creates a new game and adds a player to it.') do
      tags 'Gameplay'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          nicknme: { type: :string, example: 'Biba' },
        },
        required: [ 'nicknme' ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:payload) { {nickname: 'Biba'} }
        run_test!
      end
    end
  end

  path '/api/v1/join_game/{game_id}' do
    parameter name: 'game_id', in: :path, type: :string, description: 'Game id'
    post('Connects player to the game.') do
      tags 'Gameplay'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          nicknme: { type: :string, example: 'Biba' },
        },
        required: [ 'nicknme' ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:game_id) { first_game.id }
        let(:payload) { {nickname: 'Boba'} }
        run_test!
      end
    end
  end

  path '/api/v1/start_game' do
    post('Fills all player\'s hands and starts the game if the player goes first.') do
      tags 'Gameplay'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        run_test!
      end
    end
  end

  path '/api/v1/submit_turn' do
    post("Validates turn, updates field, refills player's hand and count player's score.") do
      tags 'Gameplay'
      consumes 'application/json'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          positions: { type: :array, items: { type: :integer }, example: [112,113,114] },
          letters: { type: :array, items: { type: :string }, example: ['с', 'о', 'н'] },
          hand: { type: :array, items: { type: :string }, example: ['з', 'й', 'ь', 'щ'] }
        },
        required: [ :positions,:letters, :hand ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:payload) { {positions: [112,113,114], letters:['с', 'о', 'н'], hand: ['з', 'й', 'ь', 'щ']} }
        run_test!
      end
    end
  end

  path '/api/v1/exchange' do
    post('Returns deleted letters from hand to letter bag and drags new ones.') do
      tags 'Gameplay'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          letters: { type: :array, items: { type: :string }, example: ['т', 'т', 'ш'] },
          hand: { type: :array, items: { type: :string }, example: ['з', 'й', 'ь', 'щ'] }
        },
        required: [ :letters, :hand ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:payload) { {letters:['т', 'т', 'ш'], hand: ['з', 'й', 'ь', 'щ']} }
        run_test!
      end
    end
  end

  path '/api/v1/leave_game' do
    post('Makes player inactive.') do
      tags 'Gameplay'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        run_test!
      end
    end
  end

  path '/api/v1/games' do
    get('List of all games in the system.') do
      tags 'Usefull'
      # consumes 'application/json'
      produces 'application/json'

      response(200, 'successful') do
        schema properties: {
          games: {
          type: :array,
          items: { '$ref' => '#/components/schemas/Game' }
          }
        }
        run_test!
      end
    end
  end

  path '/api/v1/show' do
    get('Show game by token') do
      tags 'Usefull'
      # consumes 'application/json'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string
      # parameter name: :security, in: :header, type: :string

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        run_test!
      end
    end
  end

  path '/api/v1/delete/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Game id'
    delete('Delete game.') do
      produces 'application/json'

      response(200, 'successful') do
        schema properties: {
          success: { type: :string }
        }
        let(:id) { first_game.id }
        run_test!
      end
    end
  end
end
