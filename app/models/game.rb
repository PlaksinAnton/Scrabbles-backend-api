require_relative '../../lib/array_sample'

class Game < ApplicationRecord
  has_many :players, dependent: :delete_all
  before_create :randomize_id, :set_defaults

  include AASM
  RUS_LETTER_BAG = {
    а: 10, б:3, в:5, г:3, д:5, е:9, ж:2, з:2, и:8, й:4, к:6, л:4, м:5, н:8,
    о:10, п:6, р:6, с:6, т:5, у:3, ф:1, х:2, ц:1, ч:2, ш:1, щ:1, ъ:1, ы:2, ь:2,
    э:1, ю:1, я:3, any:3
  }.freeze
  RUS_LETTERS_WEIGHTS = {
    а: 1, б:3, в:2, г:3, д:2, е:1, ж:5, з:5, и:1, й:2, к:2, л:2, м:2, н:1,
    о:1, п:2, р:2, с:2, т:2, у:3, ф:10, х:5, ц:10, ч:5, ш:10, щ:10, ъ:10, ы:5, ь:5,
    э:10, ю:10, я:3
  }.freeze
  LETTER_BONUS = [1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,
                  1,1,1,1,1,3,1,1,1,3,1,1,1,1,1,
                  1,1,1,1,1,1,2,1,2,1,1,1,1,1,1,
                  2,1,1,1,1,1,1,2,1,1,1,1,1,1,2,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,3,1,1,1,3,1,1,1,3,1,1,1,3,1,
                  1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,
                  1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,
                  1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,
                  1,3,1,1,1,3,1,1,1,3,1,1,1,3,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  2,1,1,1,1,1,1,2,1,1,1,1,1,1,2,
                  1,1,1,1,1,1,2,1,2,1,1,1,1,1,1,
                  1,1,1,1,1,3,1,1,1,3,1,1,1,1,1,
                  1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,
                ].freeze
  WORD_BONUS = [3,1,1,1,1,1,1,3,1,1,1,1,1,1,3,
                1,2,1,1,1,1,1,1,1,1,1,1,1,2,1,
                1,1,2,1,1,1,1,1,1,1,1,1,2,1,1,
                1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,
                1,1,1,1,2,1,1,1,1,1,2,1,1,1,1,
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                3,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                1,1,1,1,2,1,1,1,1,1,2,1,1,1,1,
                1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,
                1,1,2,1,1,1,1,1,1,1,1,1,2,1,1,
                1,2,1,1,1,1,1,1,1,1,1,1,1,2,1,
                3,1,1,1,1,1,1,3,1,1,1,1,1,1,3,
              ].freeze
  HAND_SIZE = 7.freeze

  aasm do 
    state :in_lobby, initial: true
    state :players_turn
    state :game_ended

    event :add_player, if: [:enough_space?, :valid_nickname?] do
      transitions from: :in_lobby, to: :in_lobby, after: :create_player
    end

    event :start, if: [:submitting_players_turn?, :enough_players?] do
      transitions from: :in_lobby, to: :players_turn, after: :fill_hands
    end

    event :next_turn, if: [:submitting_players_turn?, :valid_turn?] do
      transitions from: :players_turn, to: :players_turn, after: :process_turn
    end

    event :exchange, if: :submitting_players_turn? do
      transitions from: :players_turn, to: :players_turn, after: :exchange_letters
    end

    event :surrender, if: :submitting_players_turn? do
      transitions from: :players_turn, to: :game_ended
    end
  end

  attr_accessor :submitted_data, :created_player_id

  def set_defaults
    self.field = JSON(Array.new(225){''})
    letter_array = RUS_LETTER_BAG.each_with_object([]) do |item, letter_array|
      item[1].times { letter_array << item[0].to_s}
    end
    self.letter_bag = JSON(letter_array)
    self.current_turn = 1
    self.players_turn = 0
    self.words = JSON('[]')
  end

  def field
    JSON(super)
  end
  def letter_bag
    JSON(super)
  end
  def words
    JSON(super)
  end

  private
  def create_player(nickname)
    p = self.players.create(game_id: self.id, nickname: nickname)
    self.created_player_id = p.id
  end

  def fill_hands
    new_letter_bag = letter_bag
    
    self.players.map{ |p| p.update(hand: JSON(new_letter_bag.sample!(HAND_SIZE))) }

    self.update(letter_bag: JSON(new_letter_bag))
  end

  def process_turn
    shortfall = submitted_data[:letters].size
    new_letter_bag = self.letter_bag
    refilled_hand = submitted_data[:hand].concat(new_letter_bag.sample!(shortfall))

    player = self.players[players_turn]
    player.update(
      hand: JSON(refilled_hand), 
      score: player.score + count_score(@new_field, @new_words),
    )
    self.update(
      field: JSON(@new_field),
      letter_bag: JSON(new_letter_bag), 
      current_turn: current_turn + 1, 
      players_turn: next_players_turn, 
      words: JSON(@new_words),
    )
  end

  def exchange_letters
    shortfall = submitted_data[:letters].size
    new_letter_bag = self.letter_bag.concat(submitted_data[:letters])
    refilled_hand = submitted_data[:hand].concat(new_letter_bag.sample!(shortfall))

    self.players[players_turn].update(hand: JSON(refilled_hand))
    self.update(
      letter_bag: JSON(new_letter_bag),
      current_turn: current_turn + 1, 
      players_turn: next_players_turn
    )
  end

  def next_players_turn
    next_players_turn = self.players_turn
    begin
      next_players_turn = (next_players_turn + 1) % self.players.size
    end while self.players[next_players_turn].active_player == false
    next_players_turn
  end

  def valid_turn?
    @new_field = self.field
    submitted_data[:positions].each_with_index{|position, id| @new_field[position] = submitted_data[:letters][id] }

    words_from_field = parse_field(@new_field)
    valid_spelling?(words_from_field.map { |word| word[:spelling] })
    @new_words = words_from_field.map { |word| word[:positions] }
    true
  end

  def parse_field(new_field)
    graph = Graph.new
    words = []
    raise "At least one word must go throught central cell!" if new_field[112].blank?
  
    new_field.each_with_index do |letter, current|
      next if letter.empty?

      right = current + 1
      bottom = current + 15

      if right_letter_exists?(new_field, current)
        graph.add_edge(current, right)
        words << new_word(current, right, new_field[current], :right) unless left_letter_exists?(new_field, current)

        if bottom_letter_exists?(new_field, current)
          graph.add_edge(current, bottom)
          words << new_word(current, bottom, new_field[current], :down) unless top_letter_exists?(new_field, current)
        end

      elsif bottom_letter_exists?(new_field, current)
        graph.add_edge(current, bottom)
        words << new_word(current, bottom, new_field[current], :down) unless top_letter_exists?(new_field, current)

      elsif not graph.has_node?(current)
        raise "Not all letters are connected!"
      end
      add_current_letter_to_words(words, letter, current)
    end
    raise "Not all words are connected!" if graph.size != graph.dfs(112).size

    words
  end

  def new_word(current_id, next_id, first_letter, direction)
    { nid: next_id, spelling: first_letter.to_s, positions: [current_id], dir: direction }
  end

  def add_current_letter_to_words(words, letter, current_id)
    words.find_all{|chosen_word| chosen_word[:nid] == current_id}.each do |word|
      word[:positions] << word[:nid]
      word[:dir] == :right ? word[:nid] += 1 : word[:nid] += 15
      word[:spelling] += letter
    end
  end

  def count_score(new_field, words_positions)
    new_words_positions = words_positions - self.words
    score = 0

    new_words_positions.each do |word_positions|
      word_score = 0
      word_multiplier = 1

      word_positions.each do |letter_position|
        letter_weight = RUS_LETTERS_WEIGHTS[new_field[letter_position].to_sym]
        if submitted_data[:positions].delete(letter_position)
          letter_weight *= LETTER_BONUS[letter_position]
          word_multiplier *= WORD_BONUS[letter_position]
        end
        word_score += letter_weight
      end
      score += word_score * word_multiplier
    end
    score
  end

  def enough_space?
    raise "Not enough space for another player!" if self.players.size >= 4
    true
  end

  def valid_nickname?(nickname)
    raise "Empty nickname!" if nickname.blank?
    true
  end

  def enough_players?
    raise "Not enough players!" if self.players.size < 2
    true
  end

  def submitting_players_turn?(current_player)
    raise "It is the other player's turn!" unless self.players[players_turn].id == current_player.id
    true
  end
  
  def left_letter_exists?(field, i)
    i % 15 != 0 && field[i-1].present?
  end
  
  def right_letter_exists?(field, i)
    (i + 1) % 15 != 0 && field[i+1].present?
  end
  
  def top_letter_exists?(field, i)
    i > 14 && field[i-15].present?
  end
  
  def bottom_letter_exists?(field, i)
    i < 210 && field[i+15].present?
  end

  def valid_spelling?(words)
    dic = File.read('lib/russian_nouns.txt')
    words.each do |word|
      unless dic =~ %r{(?:^|\n)#{word}(?:$|\r)}
        raise "Words verification failed: couldn't find the word '#{word}'"
      end
    end
    true
    # File.foreach('lib/russian_nouns.txt') { |line| return true if line =~ %r{^#{word}(?:\r|$)} }
    # return false
  end

  def randomize_id
    begin
      self.id = SecureRandom.random_number(1_000_000_000)
    end while Game.exists?(id: self.id)
  end
end
