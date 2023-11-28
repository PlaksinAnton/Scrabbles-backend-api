# README

## How to get started in development mode:  

* **[Install Ruby (with rbenv)](https://github.com/rbenv/rbenv) Version 3.2.2**  

* **Clone the repository**  
	Choose the folder where you want the bot and use git clone to get this repository on your computer  
	$```git clone https://github.com/PlaksinAnton/Scrubbles-backend-api.git```  
	Get in it  
	$```scrubbles-backend-api```  

* **Install all ruby dependencies**  
	$```bundle install```  

* **Database creation**  
	$```rails db:setup```  

* **Start server**  
	$```rails s```  

## API endpoints:  
* **post 'api/v1/new_game'**  
	Awaits JSON payload with player's nickname: {"nickname": "Biba"}  
	Creates a new game and adds a player to it.  
	Returns JSON info about the game and player's JWT token in header 'Token'.  
* **post 'api/v1/join_game/:game_id'**  
	Awaits game_id in URL and JSON payload with player's nickname: {"nickname": "Boba"}  
	Connects a player to the game.  
	Returns JSON info about the game and player's JWT token in header 'Token'.  
* **post 'api/v1/start_game'**  
	Awaits token from player in header 'Authorization'.  
	Fills all player's hands and starts the game if the player goes first.  
	Returns JSON info about the game.  
* **post 'api/v1/submit_turn'** 
	Awaits token from player in header 'Authorization';
	JSON payload with a list of letters on board and player's hand: 
	{"positions": [112, 113, 114], "letters": ["б", "о", "г"], "hand": ["й", "м", "о", "ъ"]}  
	Validates turn, updates field, refills player's hand and count player's score.  
	Returns JSON info about the game.  
* **post 'api/v1/exchange'**  
	Awaits token from player in header 'Authorization';
	JSON payload with letters for exchnge and player's hand: 
	{"letters": ["т", "т", "ш"], "hand": ["р", "а", "е", "ж"]}  
	Returns deleted letters from hand to letter bag and drags new ones.  
	Returns JSON info about the game. 
* **post 'api/v1/leave_game'**  
	Awaits token from player in header 'Authorization'.  
	Makes player inactive.  
	Returns JSON info about the game. 
