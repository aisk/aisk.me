CREATE TABLE article (
	   id INTEGER PRIMARY KEY, 
	   title TEXT, 
	   content TEXT, 
	   date_create  TIMESTAMP
	   				DEFAULT (STRFTIME('%s',CURRENT_TIMESTAMP)), 
	   deleted INTEGER DEFAULT 0
);
CREATE TABLE comment (
	   id INTEGER PRIMARY KEY, 
	   article_id INTEGER, 
	   content TEXT, date_create TIMESTAMP
	   		   DEFAULT (STRFTIME('%s',CURRENT_TIMESTAMP)), 
	   deleted INTEGER DEFAULT 0
);
