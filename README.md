# Scrabble API-only application
- [About the project](#about-the-project)
    - [What?](#what)
    - [Why?](#why)
    - [State of the project](#state-of-the-project)
    - [Working app in production](#working-app-in-production)
    - [Used technologies](#used-technologies)
    - [If you've never heard of Scrabble](#if-youve-never-heard-of-scrabble)
- [API Documentation](#api-documentation)
- [Aplication overview](#aplication-overview)
  - [Game structure](#game-structure)
  - [How does authentication work](#how-does-authentication-work)
  - [Response JSON fields](#response-json-fields)
  - [Game settings](#game-settings)
- [How to run the application](#how-to-run-the-application)
    - [Ubuntu + rbenv](#ubuntu--rbenv)
- [Known issues](#known-issues)
- [Future updates](#future-updates)

## About the project
![screenshot goes here](/files/screenshot.png)  
#### What?
This is Rails API-only application that serves as a back-end web server for Scrabble game. The application is responsible for all in-game logic and serves JSON resources to an API client which is meant to be used only for visualization of game and a smooth player experience.  

#### Why?
The project was launched to provide a better alternative in terms of vocabulary to the already existing online options for Russian language players. 

#### State of the project
Currently, the project has completed the active development stage, the core game mechanics are established, and it is in the process of refining the existing game mode. Also, there are plans to introduce new game modes and English language support in the future.

#### Working app in production
[The working application with front-end](https://scrabbles.xyz).  
The front-end was provided by [aka_dude](https://codeberg.org/aka_dude) and can be found [here](https://codeberg.org/aka_dude/scramble-frontend).  

#### Used technologies
- Rails 7.0
- [JWT](https://jwt.io/introduction)
- [State machines](https://github.com/aasm/aasm)
- [Open API](https://swagger.io/specification/)
- Request testing ([rspec-rails](https://github.com/rspec/rspec-rails?tab=readme-ov-file) + [FactoryBot](https://github.com/thoughtbot/factory_bot_rails?tab=readme-ov-file))

#### If you've never heard of Scrabble
Scrabble is a word game where players use letter tiles to create words on a 15-by-15 game board. The game involves both vocabulary and strategy, as players compete to maximize their points while adhering to specific placement rules.  
Here are the full rules upon which the app was created: [rules in English](/files/scrabble_rules.pdf),  [rules in Russian](/files/правила_эрудит.pdf).

## API Documentation
[Check here](https://scrabbles.xyz/api/docs/index.html)

## Aplication overview
Here I would like to share some important details about the application architecture. This section will be useful for frontend developers or anyone seeking a better understanding of the project.

### Game structure
The game has three main states:  
- in lobby
- player's turn
- game ended

![diogram goes here](/files/game_structure_diogram.jpg)

**In lobby** - the initial state of the game before it started. The user gets into the lobby as soon as he enters his nickname. The first player who created the lobby gets to choose game settings and invite his friends (up to four people in the lobby). Friends follow the link sent by the first player, enter their nicknames and get into the lobby. As soon as everything is ready, the organizer starts the game and gets the first turn.  

**Player's turn** - in this state the game stays for the duration of play. When the game starts, a game field is initialized and players get their hands of letters. Each player gets to place letters on the field or exchange his letters, then the game iterates to the next player's turn.  

**Game ended** - this is the state of the game where players can see the final results after the game has ended. The game ends as soon as one of the participants meets the winning condition and all participants have gone the same number of times. Currently, there is only one winnig criteria is implemented - by score. When one of the players gets enough points, he gets added to a winners list. And if he is not the last one in this round, the remaining players get to play their last turn. After that, the game ends and final scores can be shown.  

### How does authentication work
Bearer Authentication is implemented through [JWT](https://jwt.io/introduction). Authentication in this project is used to distinguish one player from another and to restrict access to game information.  

Each user receives their web token via a response when entering the lobby.  Subsequently, the backend expects this token in almost every request in the 'Authorization' header. Currently, tokens is set to expire after 24 hours.

The */new_game* and */join_game/{id}* endpoints send to users their personal JWT in the 'Token' header.   Information on which requests require a token and which do not can be further explored in the [API doc](#api-documentation).  

### Response JSON fields
![json screenshot goes here](/files/json_response.png)  
Most endpoints provide an API client with all fiels that game and player objects have. Let's explore some of them.  

#### Game fields

* **players_turn**  
Player's turn is an ordinal ID of the player in the array of players. This is the main way to determine which player's turn it is now.  

* **winners**  
Winners is an array of ordinal IDs representing players who have reached the winning conditions. An array is used because there can be more than one winner.  

* **field**  
In Scrabble, the field is 15 by 15 tiles. The API serves a one-dimensional array of strings with a size of 225. Each string represents one tile, initially empty. During the game, tiles get filled in with one letter each. The conversion of the one-dimensional array to a 15x15 game field lies on the frontend.  

#### Player fields

* **nickname**  
Player's nicknames can be anything. No uniqueness is expected. By the design, no data is stored between games. Therefore, player has to enter his nickname each time he wants to play.

* **active_player**  
This is an important player's field. When it is set to false, it indicates that the player has left the game. The player no longer participates, and if there are more than two players, the game continues without the inactive player. If there are only two players, and one of them is inactive, the second one plays with himself. Thus, players who have left have the possibility to reconnect as long as the game exists. Note that the game is automaticly gets deleted when there are no more active players.  
By default, the parameter is set to true. It is the frontend's responsibility to report to the server when a player is leaving the game.  

* **want_to_end**  
This is another player's true/false vflag, that indicates their intention to stop the game. This intention should be visible to all players, allowing them to decide whether to accept or ignore it. As soon as all players are willing to end the game, the game ends immediately.  

> [!NOTE]  
> Information about other fields can be found in [API documentation](#api-documentation).  

### Game settings
Such information as letters weights and field tile bonuses are specified in [game_settings.yml](/config/game_settings.yml). Also, there are some language-dependent default values. There are default hand size and initial contents of the letter bag for russian language.  

#### Score modifiers
For the frontend, it is crucial to display special bonuses. Words and letters score modifiers are dictated by the rules of the game, and they are not meant to be changed. Therefore, their placement on the game field can be hardcoded in the frontend. The *game_settings* file can be used to ensure that all bonus tiles are located correctly. Words and letters bonuses are presented in arrays with a size of 225, where each value represents a score modifier.  

This is a more human-readable representation of modifier placement:  
![score modifiers goes here](/files/score_modifiers.jpg)  

Premium squares: 
- :green_book: green: letter score is doubled
- :ledger: yellow: letter score is tripled
- :blue_book: blue: the total score for the word is doubled
- :closed_book: red: the total score for the word is tripled

## How to run the application
#### Ubuntu + rbenv
1. [Install Ruby](https://github.com/rbenv/rbenv) Version 3.2.2  

2. Clone the repository  
```sh
git clone https://github.com/PlaksinAnton/Scrabbles-backend-api.git
```  
And get in it.  

3. Install dependencies  
```sh
bundle install
``` 

4. Create secret key that is used to encript JWT  
```sh
EDITOR=nano rails credentials:edit
```
:point_up: this command will open text editor where you can edit auto-generated secret key.  
Just close editor when you are done.   
> [!TIP]  
> You can run `$rails secret` to generate a new safe key to use 

5. Set up database  
```sh
RAILS_ENV=production rails db:setup
```

6. Start web server  
```sh
RAILS_ENV=production rails s
```
> [!NOTE]  
> To specify host and port use *-b* and *-p* options correspondingly. For example:  
> `$RAILS_ENV=production rails s -b 127.0.0.1 -p 3000`  

Now server is up and running.

## Known issues
- There is no endpoint that allows the player to return to the game.  

- The Russian dictionary is in lack of slang and swear words. :cold_sweat:

## Future updates
- Add the English language available for play.

- Give a player 15 points if he uses all his letters from his hand in one turn. 

- Subtract the weight of the letters left in the player's hand from the total score at the end of the match.

- A universal chip "*" on the board can be replaced by any player with a proper letter. The player who replaced the chip must use it on the same turn.

- New game mode - game on time. Each player will have a limited amount of time for all his moves. Whoever surpasses the time limit looses.
