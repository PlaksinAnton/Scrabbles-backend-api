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
	$```rake db:migrate```  

* **Configuration:**  
	$```bundle exec figaro install``` - creates config/application.yaml file (also adds it to .gitignore)  
	Now make up secret for jwt  
	$```echo "HMAC_SECRET: $YOUR_SECRET" >> config/application.yml```  

* **To start server use**  
	$```rails s```  

