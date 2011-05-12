 require 'sqlite3'
 db = SQLite3::Database.new( 'zapoddilg.db' )

 db.execute "

  CREATE TABLE users (
   zx_user_id INTEGER PRIMARY KEY,
   zx_user_name VARCHAR(255),
   zx_adspaces VARCHAR(1023),
   zx_pd_link VARCHAR(4095),
   zx_offline_token VARCHAR(255),
   offline_hash VARCHAR(255)
  );

 "

 puts db.complete? "SELECT * FROM users;"
 