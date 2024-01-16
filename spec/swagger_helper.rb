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
      # basePath: '/api/v1',
      components: {
        schemas: {
          Game: {
            type: 'object',
            properties: {
              id: { type: :integer, example: 982478387 },
              current_turn: { type: :integer, example: 0 },
              players_turn: { type: :integer, example: 1 },
              game_state: { type: :string, example: "in_lobby" },
              winning_score: { anyOf: [
                { type: :integer, example: 250 },
                { type: :null },
              ] },
              winners: { type: :array, items: { type: :integer }},
              field: { type: :array, items: { type: :string }},
              letter_bag: { anyOf: [
                { type: :array, items: { type: :string }},
                { type: :null },
              ] },
              language: { anyOf: [
                { type: :string},
                { type: :null },
              ] },
              hand_size: { anyOf: [
                { type: :integer },
                { type: :null },
              ] },
              players: {
                type: :array,
                items: { '$ref': '#/components/schemas/Player' }
              }
            }
          },
          Player: {
            type: 'object',
            properties: {
              id: { type: :integer, example: 12 },
              nickname: { type: :string, example: 'Biba' },
              score: { type: :integer, example: 0 },
              active_player: { type: :boolean, example: true },
              hand: { 
                type: :array, 
                items: { type: :string, example: ''}
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
          url: 'http://localhost:3000',
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
