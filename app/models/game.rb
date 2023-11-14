require 'net/http'

class Game < ApplicationRecord
  has_many :players, dependent: :delete_all
  before_create :randomize_id
  include AASM
  RUS_LETTER_BAG = {
    а: 10, б:3, в:5, г:3, д:5, е:7, ё:2, ж:2, з:2, и:8, й:4, к:6, л:4, м:5, н:8,
    о:10, п:6, р:6, с:6, т:5, у:3, ф:1, х:2, ц:1, ч:2, ш:1, щ:1, ъ:1, ы:2, ь:2,
    э:1, ю:1, я:3, any:3
  }.freeze
  HAND_SIZE = 7
  WIKI_URL = 'https://ru.wiktionary.org/w/api.php?action=query&format=json&titles=%s'

  # whiny_transitions: false
  aasm do 
    state :in_lobby, initial: true
    state :players_turn
    state :game_ended

    event :add_player, if: :enough_space? do
      transitions from: :in_lobby, to: :in_lobby, after: :create_player
    end
    
    event :start, if: [:submitting_players_turn?, :enough_players?] do
      transitions from: :in_lobby, to: :players_turn, after: :fill_hands
    end

    event :next_turn, if: [:submitting_players_turn?, :valid_turn?] do
      transitions from: :players_turn, to: :players_turn, after: :update_game
    end

    event :exchange, if: :submitting_players_turn? do
      transitions from: :players_turn, to: :players_turn, after: :exchange_letters
    end

    event :surrender, if: :submitting_players_turn? do
      transitions from: :players_turn, to: :game_ended
    end
  end

  attr_accessor :submitted_data
  
  def initialize(settings = {})
    empty_field = Array.new(15){Array.new(15){''}}
    letter_array = RUS_LETTER_BAG.each_with_object([]) do |item, letter_array|
      item[1].times { letter_array << item[0].to_s}
    end
    super(field: JSON(empty_field), letter_bag: JSON(letter_array), current_turn: 0)
  end

  def field
    JSON(super)
  end

  def letter_bag
    JSON(super)
  end


  private
  def enough_space?(_nickname)
    raise "Not enough space for another player!" if self.players.size >= 4
    true
  end

  def enough_players?(_current_player)
    raise "Not enough players!" if self.players.size < 2
    true
  end

  def submitting_players_turn?(current_player)
    raise "It is the other player's turn!" if current_player.turn_id != self.current_turn % self.players.size
    true
  end

  def valid_turn?(_current_player)
    matrix = submitted_data[:field]
    graph = Graph.new
    words = []

    raise "At least one word must go throught central cell!" if matrix[7][7].blank?
  
    matrix.each_with_index do |string, i|
      string.each_with_index do |letter, j|
        next if letter.empty?
  
        current = 15 * i + j
        right = current + 1
        bottom = current + 15
  
        if right_letter_exists?(matrix, i, j)
          graph.add_edge(current, right)
          words << new_word(right, matrix[i][j], :right) unless left_letter_exists?(matrix, i, j)
  
          if bottom_letter_exists?(matrix, i, j)
            graph.add_edge(current, bottom)
            words << new_word(bottom, matrix[i][j], :down) unless top_letter_exists?(matrix, i, j)
          end
  
        elsif bottom_letter_exists?(matrix, i, j)
          graph.add_edge(current, bottom)
          words << new_word(bottom, matrix[i][j], :down) unless top_letter_exists?(matrix, i, j)
  
        elsif not graph.has_node?(current)
          raise "Not all letters are connected!"
        end
  
        words.find_all{|word| word[:nid] == current}.each do |word|
          word[:dir] == :right ? word[:nid] += 1 : word[:nid] += 15
          word[:w] += matrix[i][j]
        end
      end
    end
  
    if graph.size != graph.dfs(112).size
      raise "Not all words are connected!"
    end

    valid_words?(words.map { |hash| hash[:w] })
  end
  
  def new_word(next_id, first_letter, direction)
    { nid: next_id, w: first_letter.to_s, dir: direction }
  end
  
  def left_letter_exists?(matrix, i, j)
    j > 0 && matrix[i][j-1].present?
  end
  
  def right_letter_exists?(matrix, i, j)
    j < 14 && matrix[i][j+1].present?
  end
  
  def top_letter_exists?(matrix, i, j)
    i > 0 && matrix[i-1][j].present?
  end 
  
  def bottom_letter_exists?(matrix, i, j)
    i < 14 && matrix[i+1][j].present?
  end

  def valid_words?(words)
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

  def take_latters_from_bag(n)
    bag = self.letter_bag
    bag_size = bag.length
    sample = []

    n.times do 
      id = SecureRandom.random_number(bag_size)
      sample << bag[id]
      bag.delete_at(id)
      bag_size -= 1
    end

    self.update(letter_bag: JSON(bag))
    sample
  end

  def fill_hands(_current_player)
    self.players.map{ |p| p.update(hand: JSON(take_latters_from_bag(HAND_SIZE))) }
  end

  def update_game(current_player)
    refill_hand(current_player)
    self.update(field: JSON(submitted_data[:field]), current_turn: current_turn + 1)
  end

  def refill_hand(current_player)
    submitted_player = submitted_data.dig(:players).find{|p| p[:id] == current_player.id}
    shortfall = HAND_SIZE - submitted_player[:hand].size

    refilled_hand = submitted_player[:hand].concat(take_latters_from_bag(shortfall))
    current_player.update(hand: JSON(refilled_hand))
  end

  def exchange_letters(current_player)
    submitted_player = submitted_data.dig(:players).find{|p| p[:id] == current_player.id}
    shortfall = HAND_SIZE - submitted_player[:hand].size

    refilled_letter_bag = self.letter_bag << (current_player.hand - submitted_player[:hand])
    self.update(letter_bag: JSON(refilled_letter_bag))

    refilled_hand = submitted_player[:hand].concat(take_latters_from_bag(shortfall))
    current_player.update(hand: JSON(refilled_hand))
  end

  def create_player(nickname)
    raise "Empty nickname!" if nickname.blank?
    
    Player.create(game_id: self.id, nickname: nickname, turn_id: self.players.size)
  end

  def randomize_id
    begin
      self.id = SecureRandom.random_number(1_000_000_000)
    end while Game.exists?(id: self.id)
  end

  def word_exists_in_wiki?(word)
    word = URI.encode_www_form_component word
  	begin
    	response = Net::HTTP.get_response(URI(WIKI_URL%word.force_encoding("ascii"))) 
  	rescue => e
      Rails.logger.fatal e
      return false
  	end

    json_response = {}
  	case response
  	when Net::HTTPSuccess then
  	  json_response = JSON(response.body)
  	else
      Rails.logger.error "Couldn't get proper response from wiki about word '#{word}'"
      return false
  	end

    json_response.dig('query', 'pages').keys.first != '-1'
  end
end
