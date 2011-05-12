require 'rubygems'
require 'sinatra'
require 'haml'
require 'zanox'
require 'sqlite'
require '../zapoddilg_keys'
require 'sqlite3'

db = SQLite3::Database.new( '../zapoddilg.db' )
db.results_as_hash = true

PARTNER_CODE_PLACEHOLDER = '%%%PC_PH%%%'


configure do
  enable :sessions
  $zanox_connect_link='https://auth.zanox-affiliate.de/login?appid=1A954C44E978336DABF8'
  Zanox::API.public_key = PUBLIC_KEY
  Zanox::API.secret_key = SECRET_KEY
  PAGE_SIZE = 50
end

get '/' do
  @connected = session[:connected]
  @profile = session[:profile]
  if(@connected)
    @userId = session[:user_id]
    @userName = session[:user_name]
    @firstName = session[:first_name]
  end
  haml :index
end

get '/auth' do
  #login here
  if(params[:authtoken])
    Zanox::API::Session.new(params[:authtoken])
    session[:connected]=true
    profile = Zanox::Profile.find()[0]
    session[:user_id] = userId = profile.xmlattr_id
    session[:first_name] = profile.firstName
    #check if user already exists
    rows = db.execute( 'SELECT * FROM users WHERE zx_user_id = :zx_user_id',
              "zx_user_id" => userId )
    #if not create a new user
    puts rows.inspect
    if rows.size < 1
      puts "new user"
      db.execute( 'INSERT INTO users(zx_user_id, zx_user_name, zx_adspaces, zx_pd_link, zx_offline_token, offline_hash)
                  VALUES  (:zx_user_id, :zx_user_name, :zx_adspaces, :zx_pd_link, :zx_offline_token, :offline_hash)',
                  "zx_user_id" => userId,
                  "zx_user_name" => profile.userName,
                  "zx_adspaces" => nil,
                  "zx_pd_link" => nil,
                  "zx_offline_token" => nil,
                  "offline_hash" => nil
                )
      session[:user_id] = profile.xmlattr_id
      session[:user_name] = profile.userName
      session[:first_name] = profile.firstName

    else
      puts "user exists"
      #update username when necessary
      if(profile.userName != rows[0]['zx_user_name'])
        db.execute( 'UPDATE users SET zx_user_name = :zx_user_name WHERE zx_user_id = :zx_user_id',
              "zx_user_id" => userId,
              "zx_user_name" => profile.userName)
      end
      #fill session parameters
      session[:user_name] = profile.userName
      session[:url] = rows[0]['zx_pd_link']
      session[:adspaces] = rows[0]['zx_adspaces']

    end
    redirect '/'
  else 
    @error = 'Login unsuccessful - could not get session'
    haml :nosuccess
  end
end

def getProgramApplications(adspaces)
  if adspaces.nil?
    puts "adspace is nil"
    programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed', :items => PAGE_SIZE)
    myPrograms = []
    myPrograms = myPrograms + programApplications

    puts programApplications.size
    page = 1
    while (programApplications.size > 0 ) do
      programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed', :items => PAGE_SIZE, :page => page)
      page+=1
      myPrograms=myPrograms + programApplications
      puts page
      puts programApplications.size
    end
    puts myPrograms.size
    return myPrograms
  else
    puts "adspace is not nil"
    myPrograms = []
    adspaces.each do |adspace| 
      programApplications = Zanox::ProgramApplication.find(:all, :adspaceId => adspace, :status => 'confirmed', :items => PAGE_SIZE)
      myPrograms = myPrograms + programApplications

      puts programApplications.size
      page = 1
      while (programApplications.size > 0 ) do
        programApplications = Zanox::ProgramApplication.find(:all, :adspaceId => adspace, :status => 'confirmed', :items => PAGE_SIZE, :page => page)
        page+=1
        myPrograms=myPrograms + programApplications
        puts page
        puts programApplications.size
      end
      puts myPrograms.size
    end
    puts myPrograms.size
    puts "Return my programs"
    return myPrograms
  end
end


get '/apps' do
  redirect '/' unless session[:connected]
  unless Zanox::API::Session.connect_id.nil?

    if session[:adspaces].nil?
      selectedAdspaces = nil
    else
      selectedAdspaces = session[:adspaces].split(',')
    end
    myPrograms = getProgramApplications(selectedAdspaces)

    deeplinks = []
    myPrograms.each do |myProgram|
      admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :programId => myProgram.program.xmlattr_id, :adspaceId => myProgram.adspace.xmlattr_id)
      deeplinks = deeplinks + admedia
    end
    
     partnerCodes = []
     deeplinks.each do |deeplink|
       code = deeplink.trackingLinks.trackingLink.ppc.scan(/^.*\/ppc\/\?(\d+C\d+)&.*/)
       partnerCodes += code[0]
     end

     pdLinks = []
     #place_holder = PARTNER_CODE_PLACEHOLDER
     subject = session[:url].to_s
     partnerCodes.each do |partnerCode|
       blubb = subject.sub(PARTNER_CODE_PLACEHOLDER,partnerCode)
       pdLinks.push(blubb)
     end

  end
  unless deeplinks.nil?
    @userId = session[:user_id]
    @userName = session[:user_name]
    @firstName = session[:first_name]
    @connected = session[:connected]
    @url = session[:url]
    @string = PARTNER_CODE_PLACEHOLDER
    
    
    @deeplinks = deeplinks
    @partnerCodes = partnerCodes
    @pdLinks = pdLinks
    haml :admedia
  else
    @connected = session[:connected]
    @error = 'Admedia could not be accessed'
    haml :nosuccess
  end
end

get '/input' do
  redirect '/' unless session[:connected]
  @connected = session[:connected]
  if @connected
    @userId = session[:user_id]
    @userName = session[:user_name]
    @firstName = session[:first_name]
    url = Zanox::Connect.ui_url()
    old = 'z_in_frm.dll?1003100310030&'
    new = 'z_in_frm.dll?1003400140010&'
    @ui_url = url.url.to_s.sub(old, new) unless url.nil?
  end
  @url=session[:url]
  haml :input
end

post '/input' do
  redirect '/' unless session[:connected]
  @connected = session[:connected]
  @userId = session[:user_id]
  @userName = session[:user_name]
  @firstName = session[:first_name]
  @showEvalMessage = true

  matches = params[:url].match(/^http:\/\/productdata.zanox.com\/((exportservice\/.*\/rest\/)|(.*)Format.aspx\?partnerCode=)(\d+C\d+)(.{4}).*/)
  if(!matches)
    @stored = false
  else
    session[:url] = params[:url].sub(matches[4],PARTNER_CODE_PLACEHOLDER)

    db.execute( 'UPDATE users SET zx_pd_link = :zx_pd_link WHERE zx_user_id = :zx_user_id',
              "zx_user_id" => session[:user_id],
              "zx_pd_link" => session[:url])
    @url=session[:url]
    @str_replacement = PARTNER_CODE_PLACEHOLDER
    @stored = true
  end

  haml :input
end

get '/links' do
  redirect '/' unless session[:connected]
  @connected = session[:connected]
  @userId = session[:user_id]
  @userName = session[:user_name]
  @firstName = session[:first_name]
  @admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :programId => 430.to_s, :adspaceId => 205575.to_s)
  haml :links
end

get '/adspaces' do
  redirect '/' unless session[:connected]
  @connected = session[:connected]
  @userId = session[:user_id]
  @userName = session[:user_name]
  @firstName = session[:first_name]
  @adspaces = Zanox::Adspace.find(:all)
  @selectedAdspaces = session[:adspaces].split(',') unless session[:adspaces].nil?
  haml :adspaces
end


post '/adspaces' do
  redirect '/' unless session[:connected]
  adspaces = []
  params.each do |param|
    keyValue = param[0].split('_')
    if(keyValue[1]=='adspace')
      adspaces = adspaces.push(param[1].to_i)
    end
  end
  session[:adspaces]= adspaces.join(',')

  db.execute( 'UPDATE users SET zx_adspaces = :zx_adspaces WHERE zx_user_id = :zx_user_id',
          "zx_user_id" => session[:user_id],
          "zx_adspaces" => session[:adspaces])

  
  @connected = session[:connected]
  @userId    = session[:user_id]
  @userName  = session[:user_name]
  @firstName = session[:first_name]
  @adspaces  = Zanox::Adspace.find(:all)
  @selectedAdspaces = session[:adspaces].split(',')
  haml :adspaces
end


get '/logout' do
  redirect '/' unless session[:connected]
  @connected = session[:connected] = false
  haml :index
end
