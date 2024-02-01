require_relative '../../lib/array_sample'

class Game < ApplicationRecord
  has_many :players, dependent: :delete_all
  before_create :randomize_id, :set_defaults

  include AASM
  SETTINGS = YAML.load_file("#{Rails.root}/config/game_settings.yml").freeze

  aasm column: :game_state do 
    state :in_lobby, initial: true
    state :players_turn
    state :game_ended

    event :add_player, if: [:enough_space?] do
      transitions from: :in_lobby, to: :in_lobby, after: :create_player
    end

    event :start, if: [:submitting_players_turn?, :enough_players?] do
      transitions from: :in_lobby, to: :players_turn, after: [:set_configuration, :fill_hands]
    end

    event :next_turn, if: [:submitting_players_turn?, :valid_turn?] do
      transitions from: :players_turn, to: :players_turn, after: :process_turn
    end

    event :exchange, if: [:submitting_players_turn?, :valid_exchange?] do
      transitions from: :players_turn, to: :players_turn, after: :exchange_letters
    end

    event :skip_turn, if: :submitting_players_turn? do
      transitions from: :players_turn, to: :players_turn, after: :update_turns
    end

    event :end_game do
      transitions from: :players_turn, to: :game_ended
    end

    event :surrender, if: :submitting_players_turn? do ##
      transitions from: :players_turn, to: :game_ended
    end
  end

  def self.correct_wrod_spelling?(word)
    dic = File.read('lib/russian_nouns.txt')
    dic =~ %r{(?:^|\n)#{word}(?:$|\r)}
  end

  attr_accessor :created_player_id

  def set_defaults
    self.current_turn = 0
    self.players_turn = 0
    self.winners = '[]'
    self.words = '[]'
    # self.letter_bag = nil   
    self.field = JSON(Array.new(225){''})
  end

  def field
    JSON(super)
  end
  def letter_bag
    l_b = super
    l_b.nil? ? nil : JSON(l_b)
  end
  def words
    JSON(super)
  end
  def winners
    JSON(super)
  end

  def game_has_a_winner?
    self.winners.present?
  end

  def all_players_are_done?
    self.players_turn == 0
  end

  def no_active_players?
    self.players.each{|p| return false if p.active_player}
    true
  end

  def as_json(options = {}) # overload for custom rendering
    json_to_return = super
    find_and_execute_custom_methods(json_to_return, options)
    return json_to_return
  end

  private
  def create_player(nickname)
    raise 'Nickname should be in string format!' unless nickname.class == String
    p = self.players.create(nickname: nickname, game_id: self.id)
    self.created_player_id = p.id
  end

  def fill_hands
    new_letter_bag = letter_bag
    
    self.players.map{ |p| p.update(hand: JSON(new_letter_bag.sample!(hand_size))) }

    self.update(letter_bag: JSON(new_letter_bag), current_turn: 1)
  end

  def set_configuration(_current_player, config_params)
    lang = config_params[:language]
    raise "Unknown language: #{lang}!" unless SETTINGS['language'].include?(lang)

    hand_size = config_params[:hand_size]
    if (not hand_size.nil?) && (hand_size.class != Integer || hand_size < 1 || hand_size > 25)
      raise "Unsuitable hand size: #{hand_size}!" 
    end
    hand_size ||= SETTINGS.dig('language', lang, 'hand_size')

    winning_score = config_params[:winning_score] 
    if (not winning_score.nil?) && (winning_score.class != Integer || winning_score < 1 || winning_score > 400)
      raise "Winning score is misspelled or to big: #{winning_score}!"
    end
    winning_score ||= SETTINGS.dig('game_mode', 'score', 'winning_score')
    
    letter_hash = SETTINGS.dig('language', lang, 'letter_bag')
    letter_array = letter_hash.each_with_object([]) do |item, letter_array|
      item[1].times { letter_array << item[0].to_s }
    end

    self.update(
      letter_bag: JSON(letter_array),
      language: lang,
      hand_size: hand_size,
      winning_score: winning_score,
    )
  end

  def process_turn(_current_player, submit_params)
    shortfall = submit_params[:letters].size
    new_letter_bag = self.letter_bag
    refilled_hand = submit_params[:hand].concat(new_letter_bag.sample!(shortfall))

    player = self.players[players_turn]
    new_score = player.score + count_score(@new_field, @new_words, submit_params)

    player.update(
      hand: JSON(refilled_hand),
      score: new_score,
    )

    winners = self.winners
    winners << self.players_turn if new_score >= self.winning_score

    self.update(
      field: JSON(@new_field),
      letter_bag: JSON(new_letter_bag),
      current_turn: current_turn + 1,
      players_turn: next_players_turn,
      winners: JSON(winners),
      words: JSON(@new_words),
    )
  end

  def exchange_letters(_current_player, exchange_params)
    shortfall = exchange_params[:exchange_letters].size
    new_letter_bag = self.letter_bag.concat(exchange_params[:exchange_letters])
    refilled_hand = exchange_params[:hand].concat(new_letter_bag.sample!(shortfall))

    self.players[players_turn].update(hand: JSON(refilled_hand))
    self.update(
      letter_bag: JSON(new_letter_bag),
      current_turn: current_turn + 1, 
      players_turn: next_players_turn
    )
  end

  def update_turns
    self.update(
      current_turn: current_turn + 1, 
      players_turn: next_players_turn
    )
  end

  def summarize_results ## meh..
    self.update(
      current_turn: current_turn - 1,
      players_turn: players_turn == 0 ? (self.players.size - 1) : (players_turn - 1),
    )
  end

  def next_players_turn
    next_players_turn = self.players_turn
    begin
      next_players_turn = (next_players_turn + 1) % self.players.size
    end while self.players[next_players_turn].active_player == false
    next_players_turn
  end

  def valid_turn?(_current_player, submit_params)
    if submit_params[:positions].size != submit_params[:letters].size
      raise "Arrays positions and letters should be the same length!"
    end
    @new_field = self.field
    submit_params[:positions].each_with_index do |position, id|
      raise "positions should be in integer format!" if position.class != Integer
      raise "This position is already occupied: #{position}" if @new_field[position].present?
      raise "letters should be in string format!" if submit_params[:letters][id].class != String
      @new_field[position] = submit_params[:letters][id]
    end
    (submit_params[:hand] || []).each{ |letter| raise "Hand letters should be in string format!" if letter.class != String }

    match_arrived_letters(submit_params[:hand] + submit_params[:letters])

    words_from_field = parse_field(@new_field)
    correct_spelling?(words_from_field.map { |word| word[:spelling] })
    @new_words = words_from_field.map { |word| word[:positions] }
    true
  end

  def correct_spelling?(words)
    dic = File.read('lib/russian_nouns.txt')
    words.each do |word|
      unless dic =~ %r{(?:^|\n)#{word}(?:$|\r)}
        raise "Words verification failed: couldn't find the word '#{word}'"
      end
    end
    true
  end

  def valid_exchange?(_current_player, exchange_params)
    exchange_params[:exchange_letters].each{ |letter| raise "exchange_letters should be in string format!" if letter.class != String }
    exchange_params[:hand].each{ |letter| raise "hand letters should be in string format!" if letter.class != String }
    match_arrived_letters(exchange_params[:exchange_letters] + exchange_params[:hand])
    true
  end

  def match_arrived_letters(arrived_letters)
    unless arrived_letters.sort == self.players[players_turn].hand.sort
      raise "Some letters were lost or added!"
    end
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

  def count_score(new_field, words_positions, submit_params)
    new_words_positions = words_positions - self.words
    score = 0

    new_words_positions.each do |word_positions|
      word_score = 0
      word_multiplier = 1

      word_positions.each do |letter_position|
        letter_weights = SETTINGS.dig('language', self.language, 'letter_weights')
        letter_weight = letter_weights[new_field[letter_position]]
        if submit_params[:positions].delete(letter_position)
          letter_weight *= SETTINGS['letter_bonus'][letter_position]
          word_multiplier *= SETTINGS['word_bonus'][letter_position]
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

  # def valid_nickname?(nickname) # уже реализовано в контроллере
  #   raise "Empty nickname!" if nickname.blank?
  #   true
  # end

  def enough_players?
    raise "Not enough players!" if self.players.size < 2
    true
  end

  def submitting_players_turn?(current_player)
    id = self.players[players_turn].id
    raise "It is the other player's turn: #{id}!" unless current_player.id == id
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

  def randomize_id
    begin
      self.id = SecureRandom.random_number(1_000_000_000)
    end while Game.exists?(id: self.id)
  end

  def find_and_execute_custom_methods(json_to_return={}, options = {}) # for custom rendering
    if options&.has_key?(:custom_methods) && json_to_return.present?
      options[:custom_methods].keys.each do |method_key|
        self.send(method_key, json_to_return, options[:custom_methods][method_key])
      end
    end
    if options&.has_key?(:include) && json_to_return.present?
      options[:include].keys.each do |key|
        find_and_execute_custom_methods(json_to_return[key.to_s], options[:include][key])
      end
    end
  end

  def hide_hands(players_array, exept_this_player) # custom method for rendering
    players_array.each do |player|
      next if player['id'] == exept_this_player
      player['hand'] = ["don't peek ;)"] unless player['hand'].empty?
    end
  end
end
