# frozen_string_literal: true
require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API',
        version: '1'
      },
      components: {
        schemas: {
          Game: {
            type: 'object',
            properties: {
              id: { type: :integer, example: 982478387, description: "Used for joinnin the game." },
              current_turn: { type: :integer, example: 0, description: "The current move in the order." },
              players_turn: { type: :integer, example: 1, description: "An ordinal ID of the player in the array of players. (This is different than player's id field)." },
              game_state: { type: :string, example: "in_lobby", description: "One of the three main game states: in_lobby, players_turn, game_ended." },
              winning_score: { anyOf: [
                { type: :integer, example: 250 },
                { type: :null },
              ], description: "Score that is nessesary to get to win the game." },
              winners: { type: :array, items: { type: :integer }, description: "Array of player's ordinal IDs who have met winning criteria." },
              field: { type: :array, items: { type: :string }, description: "This is the game field where letters are supposed to go, consisting of 225 initially blank tiles." },
              letter_bag: { anyOf: [
                { type: :array, items: { type: :string } },
                { type: :null },
              ], description: "Array of letters from which players draw their hands." },
              language: { anyOf: [
                { type: :string},
                { type: :null },
              ], description: "Language of letters that players use to play." },
              hand_size: { anyOf: [
                { type: :integer },
                { type: :null },
              ], description: "The number of letters each player draw." },
              players: {
                type: :array,
                items: { '$ref': '#/components/schemas/Player' },
                description: "The array of players",
              }
            }
          },
          Player: {
            type: 'object',
            properties: {
              id: { type: :integer, example: 12, description: "Unique player id. Don't have much use for now." },
              nickname: { type: :string, example: 'Biba', description: "No uniqueness is required." },
              score: { type: :integer, example: 0, description: "The personal score of the player." },
              active_player: { type: :boolean, example: true, description: "The flag that signifies whether the player is in game or has left it." },
              want_to_end: { type: :boolean, example: false, description: "The flag that signifies if the player wants to finish the game." },
              hand: { 
                type: :array, 
                items: { type: :string, example: ''},
                description: "Letters that player are 'holding'.", 
              }
            }
          }
        },
        securitySchemes: {
            JWT: {
            # type: :JWT,
            # scheme: :bearer, ##
            name: 'Authorization',
            in: :header,
            # bearerFormat: :JWT 
          }
        }
      },
      paths: {},
      servers: [
        {
          url: 'https://scrabbles.xyz',
          # variables: {
          #   defaultHost: {
          #     default: 'www.example.com'
          #   }
          # }
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
