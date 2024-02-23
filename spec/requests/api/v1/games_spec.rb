require 'swagger_helper'
# https://coderwall.com/p/bbxb8g/use-ruby-debugger-when-debugging-rspecs

RSpec.describe 'api/v1/games', type: :request do

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

      response 201, 'Game created' do
        schema properties: {
          game: { '$ref' => '#/components/schemas/game_in_lobby' }
        }
        header :Token, type: :string, description: "Player's personal token"
        let(:payload) { {'nickname': 'Biba'} }
        run_test! do |response|
          expect(response.header['Token']).not_to be nil
          decoded_token = Authentication.decode_token(response.header['Token'])
          game = Game.find_by(id: decoded_token[0]['game'])
          expect(game.id).not_to be nil
          expect(game.players.find_by(id: decoded_token[0]['sub']).id).not_to be nil
          
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:current_turn]).to eq 0
          expect(game_body[:players_turn]).to eq 0
          expect(game_body[:game_state]).to eq 'in_lobby'
          expect(game_body[:field].size).to eq 225 
          expect(game_body[:field].uniq).to eq [''] 
          expect(game_body[:players].size).to eq 1
          expect(game_body[:players].first[:nickname]).to eq 'Biba'
          expect(game_body[:players].first[:score]).to eq 0
          expect(game_body[:players].first[:active_player]).to eq true
          expect(game_body[:players].first[:want_to_end]).to eq false
          expect(game_body[:players].first[:hand]).to eq []
        end
      end

      response 400, 'Nickname should be string' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:payload) { {'nickname': 999} }
        run_test!
      end

      response 400, 'No nickname provided' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:payload) { {'nothing': 'something'} }
        run_test!
      end
    end
  end

  path '/api/v1/join_game/{game_id}' do
    parameter name: :game_id, in: :path, type: :string, description: 'Game id'
    post('Connects a new player to the game lobby.') do
      tags 'Gameplay'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          nickname: { type: :string, example: 'Boba' },
        },
        required: [ :nickname ]
      }

      response(200, 'Player joined to the game') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/game_in_lobby' }
        }
        header :Token, type: :string, description: "Player's personal token"
        let(:game) { create(:game) }
        let(:game_id) { game.id }
        let(:payload) { {'nickname': 'Boba'} }
        run_test! do |response|
          expect(response.header['Token']).not_to be nil
          decoded_token = Authentication.decode_token(response.header['Token'])
          expect(decoded_token[0]['game']).to eq game_id
          expect(decoded_token[0]['sub']).to be game.players.second.id
          
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:players].size).to eq 2
          expect(game_body[:players].second[:nickname]).to eq 'Boba'
          expect(game_body[:players].second[:score]).to eq 0
          expect(game_body[:players].second[:active_player]).to eq true
          expect(game_body[:players].second[:want_to_end]).to eq false
          expect(game_body[:players].second[:hand]).to eq []
        end
      end

      response 400, 'Game not found! Wrong game id' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:game_id) { 123456789 }
        let(:payload) { {'nickname': 'Boba'} }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq 'Game not found!'
        end
      end

      response 400, 'Too much players' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:game_id) { create(:game, players_count: 4).id }
        let(:payload) { {'nickname': 'Boba'} }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq 'Not enough space for another player!'
        end
      end

      response 405, 'Invalid transition' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:game_id) { create(:active_game).id }
        let(:payload) { {'nickname': 'Boba'} }
        run_test!
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
          language: { type: :string, example: 'rus', description: 'Only russian is availible for now.' },
          hand_size: { type: :integer, example: '8', description: 'Default value for russian is 7.' },
          winning_score: { type: :integer, example: '120', description: 'Default value is 150.' }
        },
        required: [ :language ]
      }

      response(200, 'Only required fields are specified') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/active_game' }
        }
        let(:payload) { { "language": "rus" } }
        let(:Authorization) { 
          game = create(:game, players_count: 2)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:current_turn]).to eq 1
          expect(game_body[:players_turn]).to eq 0
          expect(game_body[:game_state]).to eq 'players_turn'
          expect(game_body[:field].size).to eq 225
          expect(game_body[:field].uniq).to eq ['']
          expect(game_body[:winning_score]).to eq 150
          expect(game_body[:winners]).to eq []
          expect(game_body[:letter_bag].uniq.size).to be > 20
          expect(game_body[:language]).to eq 'rus'
          expect(game_body[:hand_size]).to eq 7
          expect(game_body[:players].first[:hand].size).to eq 7
          expect(game_body[:players].second[:hand].first).to eq "don't peek ;)"
        end
      end

      response(200, 'All fields are specified') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/active_game' }
        }
        let(:payload) { { "language": "rus", "hand_size": 8, "winning_score": 100 } }
        let(:Authorization) { 
          game = create(:game, players_count: 2)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:current_turn]).to eq 1
          expect(game_body[:players_turn]).to eq 0
          expect(game_body[:game_state]).to eq 'players_turn'
          expect(game_body[:field].size).to eq 225
          expect(game_body[:field].uniq).to eq ['']
          expect(game_body[:winning_score]).to eq 100
          expect(game_body[:winners]).to eq []
          expect(game_body[:letter_bag].uniq.size).to be > 20
          expect(game_body[:language]).to eq 'rus'
          expect(game_body[:hand_size]).to eq 8
          expect(game_body[:players].first[:hand].size).to eq 8
          expect(game_body[:players].second[:hand].first).to eq "don't peek ;)"
        end
      end

      response(400, 'Required fields are absent') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { "hand_size": 8, "winning_score": 100 } }
        let(:Authorization) { 
          game = create(:game, players_count: 2)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test!
      end

      response(400, 'Wrong player tries to start the game') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:game, players_count: 2) }
        let(:payload) { { "language": "rus" } }
        let(:Authorization) { Authentication.generate_token(game.players.second.id, game.id) }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "It is the other player's turn: #{game.players_turn}!"
        end
      end

      response(400, 'Not enough players') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { "language": "rus" } }
        let(:Authorization) { 
          game = create(:game)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Not enough players!"
        end
      end

      response(400, 'Unknown language') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { "language": "sus" } }
        let(:Authorization) { 
          game = create(:game, players_count: 2)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Unknown language: sus!"
        end
      end

      response(400, 'Unsuitable hand size') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { "language": "rus", "hand_size": 100500 } }
        let(:Authorization) { 
          game = create(:game, players_count: 2)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Unsuitable hand size: 100500! It should be between 1 and 25."
        end
      end

      response(400, 'Unsuitable winning score') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { "language": "rus", "winning_score": -2 } }
        let(:Authorization) { 
          game = create(:game, players_count: 2)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Unsuitable winning score: -2! It should be between 1 and 400."
        end
      end

      response 405, 'Invalid transition' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:payload) { { "language": "rus" } }
        let(:Authorization) { 
          game = create(:active_game)
          Authentication.generate_token(game.players.first.id, game.id)
        }
        run_test!
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

      response(200, 'First word is submitted') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/active_game' }
        }
        let(:game) {
          game = create(:active_game, hand_size: 24)
          while not (game.players.first.hand.include?('а') && game.players.first.hand.include?('с')) 
            game = create(:active_game, hand_size: 24)
          end
          game
        }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) {
          hand = game.players.first.hand 
          hand.delete_at(hand.index('а'))
          hand.delete_at(hand.index('с'))
          { positions: [112,113], letters:['а', 'с'], hand: hand }
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:current_turn]).to eq 2
          expect(game_body[:players_turn]).to eq 1
          expect(game_body[:game_state]).to eq 'players_turn'
          expect(game_body[:field].size).to eq 225
          expect(game_body[:field][112]).to eq 'а'
          expect(game_body[:field][113]).to eq 'с'
          expect(game_body[:winners]).to eq []
          expect(game_body[:players].first[:score]).to be > 0
          expect(game_body[:players].first[:hand].size).to be 24
          expect(game_body[:players].second[:hand].first).to eq "don't peek ;)"
        end
      end

      response(200, 'Word is attached to existing one') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/active_game' }
        }
        let(:game) { 
          game = create(:active_game_with_word, hand_size: 24)
          while not game.players.first.hand.include?('с')
            game = create(:active_game_with_word, hand_size: 24)
          end
          game
        }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { 
          hand = game.players.first.hand
          hand.delete_at(hand.index('с'))
          { positions: [128], letters:['с'], hand: hand } 
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:field].size).to eq 225
          expect(game_body[:field][113]).to eq 'а'
          expect(game_body[:field][128]).to eq 'с'
          expect(game_body[:winners]).to eq []
          expect(game_body[:players].first[:hand].size).to be 24
          expect(game_body[:players].second[:hand].first).to eq "don't peek ;)"
        end
      end

      response(400, "Submitted word doesn't exist") do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) {
          game = create(:active_game, hand_size: 24)
          while not (game.players.first.hand.include?('а') && game.players.first.hand.include?('к')) 
            game = create(:active_game, hand_size: 24)
          end
          game
        }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) {
          hand = game.players.first.hand 
          hand.delete_at(hand.index('а'))
          hand.delete_at(hand.index('к'))
          { positions: [112,113], letters:['а', 'к'], hand: hand }
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Words verification failed: couldn't find the word 'ак'"
        end
      end

      response(400, 'Wrong player tries to start the game') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:payload) { { positions: [112,113], letters:['а', 'с'], hand: ['з', 'й', 'ь', 'щ', 'о'] } }
        let(:Authorization) { Authentication.generate_token(game.players.second.id, game.id) }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "It is the other player's turn: #{game.players_turn}!"
        end
      end

      response(400, 'Bad payload') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: [112,113,114], letters:['а', 'с'], hand: ['з', 'й', 'ь', 'щ', 'о'] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Arrays positions and letters should be the same length!"
        end
      end

      response(400, 'Bad positions payload format') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: ['112','113'], letters:['а', 'с'], hand: ['з', 'й', 'ь', 'щ', 'о'] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "positions should be in integer format!"
        end
      end

      response(400, 'Bad letters payload format') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: [112,113], letters:[11, 12], hand: ['з', 'й', 'ь', 'щ', 'о'] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "letters should be in string format!"
        end
      end

      response(400, 'Bad hand payload format') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: [112,113], letters:['а', 'с'], hand: [1,2,3,4,5] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "hand should be in string format!"
        end
      end

      let(:game) {
        game = create(:active_game_with_word, hand_size: 24, word: ['в','а','з','а'])
        while not (game.players.first.hand.include?('а') && game.players.first.hand.include?('с')) 
          game = create(:active_game_with_word, hand_size: 24)
        end
        game
      }
      let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
      let(:hand) {
        hand = game.players.first.hand 
        hand.delete_at(hand.index('а'))
        hand.delete_at(hand.index('с'))
        hand
      }

      response(400, 'Trying to submit letter over existing one') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { positions: [112,113], letters:['а', 'с'], hand: hand } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "This position is already occupied: 112"
        end
      end

      response(400, 'Incorrect positions are submitted') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { positions: [1112,1113], letters:['а', 'с'], hand: hand } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "positions should be in range of 0 and 224!"
        end
      end

      response(400, 'Submitted word has no connection to the existing one') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:payload) { { positions: [142,143], letters:['а', 'с'], hand: hand } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Not all words are connected!"
        end
      end

      response(400, 'Incorrect letters are submitted') do 
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: [112,113], letters:['а', 'с'], hand: ['е','н','с','п','р'] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Some letters were lost or added!"
        end
      end

      response(400, "First submit doesn't include central cell") do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) {
          game = create(:active_game, hand_size: 24)
          while not (game.players.first.hand.include?('а') && game.players.first.hand.include?('с')) 
            game = create(:active_game, hand_size: 24)
          end
          game
        }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) {
          hand = game.players.first.hand 
          hand.delete_at(hand.index('а'))
          hand.delete_at(hand.index('с'))
          { positions: [113,114], letters:['а', 'с'], hand: hand }
        }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "At least one word must go throught central cell!"
        end
      end

      response(400, 'Trying to submit stand alone letter') do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game_with_word) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: [143], letters:[game.players.first.hand.first], hand: game.players.first.hand[1..-1] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Not all letters are connected!"
        end
      end

      response(400, "Submitted word doesn't exist") do
        schema properties: { error: { type: :int } }, required: [ :error ]
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { positions: [112,113,114,115,116,117,118], letters: game.players.first.hand, hand: [] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          expect(body[:error]).to eq "Words verification failed: couldn't find the word '#{game.players.first.hand.join('')}'"
        end
      end

      response 405, 'Invalid transition' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:payload) { { positions: [112,113], letters:['а', 'с'], hand: ['з', 'й', 'ь', 'щ', 'о'] } }
        let(:Authorization) { 
          game = create(:game)
          Authentication.generate_token(game.players.first.id, game.id)
        }
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

      response(200, 'Sucsessfull exchange') do
        schema properties: {
          game: { '$ref' => '#/components/schemas/active_game' }
        }
        let(:game) { create(:active_game) }
        let(:Authorization) { Authentication.generate_token(game.players.first.id, game.id) }
        let(:payload) { { exchange_letters: game.players.first.hand[0..3], hand: game.players.first.hand[4..6] } }
        run_test! do |response|
          body = JSON(response.body, symbolize_names: true)
          game_body = body[:game]
          expect(game_body[:current_turn]).to eq 2
          expect(game_body[:players_turn]).to eq 1
          expect(game_body[:game_state]).to eq 'players_turn'
          expect(game_body[:field].size).to eq 225
          expect(game_body[:field].uniq).to eq ['']
          expect(game_body[:winners]).to eq []
          expect(game_body[:players].first[:score]).to be 0
          expect(game_body[:players].first[:hand].size).to be 7
          expect(game_body[:players].second[:hand].first).to eq "don't peek ;)"
        end
      end

      response 405, 'Invalid transition' do
        schema properties: { error: { type: :string } }, required: [ :error ]
        let(:payload) { { exchange_letters:['а', 'с'], hand: ['з', 'й', 'ь', 'щ', 'о'] } }
        let(:Authorization) {
          game = create(:game)
          Authentication.generate_token(game.players.first.id, game.id)
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
