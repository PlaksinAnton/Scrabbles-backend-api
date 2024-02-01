require 'swagger_helper'
# require 'ruby-debug'
# https://coderwall.com/p/bbxb8g/use-ruby-debugger-when-debugging-rspecs

RSpec.describe 'api/v1/games', type: :request do

  let!(:first_game) { first_game = create(:game); first_game.add_player!('Biba'); first_game }
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
          nickname: { type: :string, example: 'Biba' },
        },
        required: [ :nickname ]
      }

      response(201, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        header :Token, type: :string, description: 'Player\'s personal token'
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
          nickname: { type: :string, example: 'Biba' },
        },
        required: [ :nickname ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        header :Token, type: :string, description: 'Player\'s personal token'
        let(:game_id) { first_game.id }
        let(:payload) { {nickname: 'Boba'} }
        run_test! do |response|
          debugger
        end
      end
    end
  end

  path '/api/v1/start_game' do
    post('Fills all player\'s hands and starts the game with chosen settings.') do
      tags 'Gameplay'
      consumes 'application/json'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          language: { type: :string, example: 'rus', description: 'Only russian for now.' },
          hand_size: { type: :integer, example: '8', description: 'Default for russian is 7.' },
          winning_score: { type: :integer, example: '120', description: 'Default is 150.' }
        },
        required: [ :language ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:payload) { { language: "rus", hand_size: 8 } }
        run_test!
        # run_test! do |response|
        #   data = JSON.parse(response.body)
        #   expect(data['error']).to eq('Not enough players!')
        # end
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
        required: [ :positions, :letters, :hand ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:payload) { {positions: [112,113,114], letters:['с', 'о', 'н'], hand: ['з', 'й', 'ь', 'м']} }
        run_test!
      end
    end
  end

  path '/api/v1/exchange' do
    post('Returns deleted letters from hand to letter bag and drags new ones.') do
      tags 'Gameplay'
      consumes 'application/json'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          exchange_letters: { type: :array, items: { type: :string }, example: ['т', 'т', 'ш'] },
          hand: { type: :array, items: { type: :string }, example: ['з', 'й', 'ь', 'щ'] }
        },
        required: [ :exchange_letters, :hand ]
      }

      response(200, 'successful') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/Game' }
        }
        let(:payload) { {exchange_letters:['т', 'т', 'ш'], hand: ['з', 'й', 'ь', 'щ']} }
        run_test!
      end
    end
  end

  path '/api/v1/skip_turn' do
    post('Allows player to skip his turn.') do
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

  path '/api/v1/leave_game' do
    post("Sets player's 'active_player' flag to false.
    An inactive player is considered to have left the game and skips his turns. 
    When there are no active players, the game is deleted.") do
      tags 'Gameplay'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string

      response(200, 'successful') do
        schema properties: {
          success: { type: :string, example: "Player left the game!" }
        }
        run_test!
      end
    end
  end

  path '/api/v1/suggest_finishing' do
    post("Sets player's 'want_to_end' flag to true. 
    As soon as all players 'want to end', game ends prematurely.") do
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

  path '/api/v1/spelling_check' do
    post('Check if the specified word is in the dictionary.') do
      tags 'Optional'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          word: { type: :string, example: "слово" },
        },
        required: [ :word ]
      }

      response(200, 'successful') do
        schema properties: {
          correct_spelling: { type: :boolean, example: true },
        }
        let(:payload) { { word: "слово" } }
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
end
