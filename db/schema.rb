# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_11_28_161458) do
  create_table "games", force: :cascade do |t|
    t.integer "current_turn", null: false
    t.integer "players_turn", null: false
    t.string "game_state", null: false
    t.integer "winning_score"
    t.string "winners", null: false
    t.string "words", null: false
    t.string "field", null: false
    t.string "letter_bag"
    t.string "language"
    t.integer "hand_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "nickname", null: false
    t.integer "score", null: false
    t.boolean "active_player", null: false
    t.string "hand", null: false
    t.integer "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_players_on_game_id"
  end

  add_foreign_key "players", "games"
end
