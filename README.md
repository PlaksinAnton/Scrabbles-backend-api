# Scrabble API-only application

## About the project
![screenshot goes here](/files/screenshot.png)
#### What?
This is Rails API-only application that serves as a back-end web server for Scrabble game. The application is responsible for all in-game logic and serves JSON resources to an API client which is meant to be used only for visualization of game and a smooth player experience.  

#### Why?
The project was launched to provide a better alternative in terms of vocabulary to the already existing online options for Russian language players. 

#### State of the project
Currently, the project has completed the active development stage, the core game mechanics are established, and it is in the process of refining the existing game mode. Also, there are plans to introduce new game modes, and English language support in the future.

#### Working app in production
[The working application with front-end](http://localhost:8080/new_game) (comming soon).  
The front-end was provided by [aka_dude](https://codeberg.org/aka_dude) and can be found [here](https://codeberg.org/aka_dude/scramble-frontend).  

#### Used technologies
- Rails 7.0
- JWT authentication
- [AASM](https://github.com/aasm/aasm)
- Open API

#### If you've never heard of Scrabble
Scrabble is a word game where players use letter tiles to create words on a 15-by-15 game board. The game involves both vocabulary and strategy, as players compete to maximize their points while adhering to specific placement rules.  
Here are the full rules upon which the app was created: [rules in English](/files/scrabble_rules.pdf),  [rules in Russian](/files/правила_эрудит.pdf).

## Documentation  
Comming soon. For now you can see it if you run application locally. It will be by this url http://localhost:8081/api/docs/index.html


## Game structure
The game has three main states:  
- in lobby
- player's turn
- game ended

![diogram goes here](/files/game_structure_diogram.jpg)

**In lobby** - the initial state of the game before it started. The user gets into the lobby as soon as he enters his nickname. The first player who created the lobby gets to choose game settings and invite his friends (up to four people in the lobby). Friends follow the link sent by the first player, enter their nicknames and get into the lobby. As soon as everything is ready, the organizer starts the game and gets the first turn.  

**Player's turn** - in this state the game stays for the duration of play. When the game starts, a game field is initialized and players get their hands of letters. Each player gets to place letters on the field or exchange his letters, then the game iterates to the next player's turn.  

**Game ended** - this is state of the game where players can see the final results after the game has ended. The game ends as soon as one of the participants meets the winning condition and all participants have gone the same number of times. Currently, there is only one winnig criteria is implemented - by score. When one of the players gets enough points, he gets added to a winners list. And if he is not the last one in this round, the remaining players get to play their last turn. After that, the game ends and final scores can be shown.  

## How to run the application
#### Ubuntu + rbenv
1. [Install Ruby](https://github.com/rbenv/rbenv) Version 3.2.2  

2. Clone the repository  
`$git clone https://github.com/PlaksinAnton/Scrubbles-backend-api.git`  
And get in it.  

3. Install dependencies  
`$bundle install`  

4. Set up database  
`$RAILS_ENV=production rails db:setup`  

5. Create secret key that is used to encript JWT  
`$rails credential:edit` - this command will open text editor where you can edit auto-generated secret key if you like.  
Just close editor when you are done.   
  > [!TIP]  
  > You can run `$rails secret` to generate a new safe key to use 

6. Start web server  
`$RAILS_ENV=production rails s`  
  > [!NOTE]  
  > To specify host and port use *-b* and *-p* options correspondingly. For example:  
  > `$RAILS_ENV=production rails s -b 127.0.0.1 -p 3000`  

Now server is up and running.

## Known issues
- The Russian dictionary is in lack of some slang and swear words. :cold_sweat:

- There is no surrender or finish game button. This button can be usefull in case winning score is set to hight up and nobody reached it but all letters from bag are out, so there are no availible moves.

## Future updates
- Add english language availible for play.

- Give player 15 points in case he used all his letters from his hand in one turn. 

- Subtract weight of the letters left in player's hand from the total score at the end of the match.

- A universal chip "*" on the board can be replaced by any player with a proper letter. The player who replaced the chip must use it on the same turn.

- New game mode - game on time. Each player will have a limited amount of time for all his moves. Whoever surpasses the time limit looses.
