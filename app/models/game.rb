require 'net/http'

class Game < ApplicationRecord
  has_many :players, dependent: :delete_all
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
    state :player_turn
    state :retrying_turn
    state :game_ended
    
    event :start, after: :fill_players_hands do
      transitions from: :in_lobby, to: :player_turn, if: :enough_players?
    end

    event :next_turn, after: :update_game do
      transitions from: [:retrying_turn, :player_turn], to: :player_turn, if: :valid_turn?
    end

    event :retry_turn do
      transitions from: [:retrying_turn, :player_turn], to: :retrying_turn
    end

    event :surrender do
      transitions from: [:player_turn, :retrying_turn], to: :game_ended
    end
  end

  attr_accessor :submited_data # game_id field p_id hand_id
  
  def initialize(settings = {})
    empty_field = JSON(Array.new(15){Array.new(15){''}})
    letter_array = RUS_LETTER_BAG.each_with_object([]) do |item, letter_array|
      item[1].times { letter_array << item[0].to_s}
    end
    super(field: empty_field, letter_bag: JSON(letter_array), current_turn: 0)
  end

  def field_array
    JSON(self.field)
  end

  def bag_array
    JSON(self.letter_bag)
  end
  
  def aasm_event_failed(start, in_lobby)
    # use custom exception/messages, report metrics, etc
  end

  private
  def enough_players?
    self.players.size >= 2
  end

  def valid_turn?
    matrix = submited_data[:field_array]
    graph = Graph.new
    words = []
  
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
          Rails.logger.info "Fast adjacency check failed"
          return false
        end
  
        words.find_all{|word| word[:nid] == current}.each do |word|
          word[:dir] == :right ? word[:nid] += 1 : word[:nid] += 15
          word[:w] += matrix[i][j]
        end
      end
    end
  
    if graph.size != graph.dfs(112).size
      Rails.logger.info "Adjacency check failed"
      return false
    end

    return false unless valid_words?(words.map { |hash| hash[:w] })

    Rails.logger.info "Valid turn"
    true
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

  def take_latters_from_bag(n)
    letter_array = JSON(self.letter_bag)
    arr_length = letter_array.length
    sample = []

    n.times do 
      id = rand(arr_length)
      sample << letter_array[id]
      letter_array.delete_at(id)
      arr_length -= 1
    end

    self.update(letter_bag: JSON(letter_array))
    sample
  end

  def fill_players_hands
    self.players.map{ |p| p.update(hand: JSON(take_latters_from_bag(HAND_SIZE))) }
  end

  def update_game
    refill_players_hand
    self.update(field: JSON(submited_data[:field_array]), current_turn: current_turn + 1)
  end

  def refill_players_hand
    current_turn_id = current_turn % self.players.size
    submited_player = submited_data.dig(:players).find{|p| p[:turn_id] == current_turn_id}
    shortfall = HAND_SIZE - submited_player[:hand_array].size
    refilled_hand = submited_player[:hand_array].concat(take_latters_from_bag(shortfall))
    self.players.find_by(turn_id: current_turn_id).update(hand: JSON(refilled_hand))
  end

  def valid_words?(words)
    dic = File.read('lib/russian_nouns.txt')
    words.each do |word|
      unless dic =~ %r{(?:^|\n)#{word}(?:$|\r)}
        Rails.logger.info "Words check failed: couldn't find the word '#{word}'"
        return false
      end
    end
    true
    # File.foreach('lib/russian_nouns.txt') { |line| return true if line =~ %r{^#{word}(?:\r|$)} }
    # return false
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
