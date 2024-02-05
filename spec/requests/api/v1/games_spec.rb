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
    post('Connects a new player to the game lobby.') do
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
    post("Changes the game state, sets the winning score, fills up the letter bag, 
    then player's hands and sets other initial fields.") do
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
    post("Validates submitted  data, updates the game field, refills the player's hand, 
    and calculates the score. Passes the turn.") do
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
    post("Returns letters for exchange to the letter bag and draws new ones as replacement. 
    Passes the turn.") do
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

  path '/api/v1/leave_game' do
    post("Sets player's 'active_player' flag to false. An inactive player skips his turns. 
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

  path '/api/v1/skip_turn' do
    post('Passes the turn.') do
      tags 'Optional'
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
    post('Checks if the specified word is present in the dictionary.') do
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

  path '/api/v1/show' do
    get('Deprecated, use status instead.') do
      tags 'Usefull'
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

  path '/api/v1/status' do
    get('Displays the full current game state.') do
      tags 'Usefull'
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

  path '/api/v1/quick_status' do
    get('Displays the minimalistic game status.') do
      tags 'Usefull'
      produces 'application/json'
      security [ JWT: {} ]
      parameter name: :Authorization, in: :header, type: :string

      response(200, 'successful') do
        schema properties: {
          game: {
            type: 'object',
            properties: {
              id: { type: :integer, example: 982478387 },
              players_turn: { type: :integer, example: 1 },
              game_state: { type: :string, example: "in_lobby" },
              players: {
                type: :array,
                items: { 
                  type: 'object',
                  properties: {
                    id: { type: :integer, example: 12 },
                    active_player: { type: :boolean, example: true },
                    want_to_end: { type: :boolean, example: false }, 
                  }
                }
              }
            }
          }
        }
        run_test!
      end
    end
  end

end
