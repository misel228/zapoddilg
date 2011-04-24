require 'rubygems'
require 'sinatra'
require 'haml'
require 'zanox'
require '../zapoddilg_keys'


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
    profile = Zanox::Profile.find()[0]
    @userId = session[:user_id] = profile.xmlattr_id
    @userName = session[:user_name] = profile.userName
    @firstName = session[:first_name] = profile.firstName
  end
  haml :index
end

get '/auth' do
  #login here
  if(params[:authtoken])
    Zanox::API::Session.new(params[:authtoken])
    session[:connected]=true
    redirect '/'
  else 
    @error = 'Login unsuccessful - could not get session'
    haml :nosuccess
  end
end

get '/apps' do
  unless Zanox::API::Session.connect_id.nil?
    programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed', :items => PAGE_SIZE)
    myPrograms = []
    myPrograms = myPrograms + programApplications

    page = 1
    while (programApplications.size > 0 ) do
      programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed', :items => PAGE_SIZE, :page => page)
      page+=1
      myPrograms=myPrograms + programApplications
    end

    deeplinks = []
    myPrograms.each do |myProgram|
      admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :programId => myProgram.program.xmlattr_id, :adspaceId => myProgram.adspace.xmlattr_id)
      deeplinks = deeplinks + admedia
    end
    
#    /^.*\/ppc\/\?(\d+C\d+)&.*/
#    myarray = mystring.scan(/^.*\/ppc\/\?(\d+C\d+)&.*/)
     partnerCodes = []
     deeplinks.each do |deeplink|
       code = deeplink.trackingLinks.trackingLink.ppc.scan(/^.*\/ppc\/\?(\d+C\d+)&.*/)
       partnerCodes += code[0]
     end

     pdLinks = []
     place_holder = session[:str_replacement].to_s
     subject = session[:url].to_s
     partnerCodes.each do |partnerCode|
       blubb = subject.sub(place_holder,partnerCode)
       pdLinks.push(blubb)
     end

  end
  unless deeplinks.nil?
    @userId = session[:user_id]
    @userName = session[:user_name]
    @firstName = session[:first_name]
    @connected = session[:connected]
    @url = session[:url]
    @string = session[:str_replacement]
    
    
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
  @connected = session[:connected]
  if @connected
    @userId = session[:user_id]
    @userName = session[:user_name]
    @firstName = session[:first_name]
    url = Zanox::Connect.ui_url()
    old = 'z_in_frm.dll?1003100310030&'
    new = 'z_in_frm.dll?1003400140010&'
    @ui_url = url.url.to_s.sub(old, new)
  end
  @url=session[:url]
  haml :input
end

post '/input' do
  @connected = session[:connected]
  @userId = session[:user_id]
  @userName = session[:user_name]
  @firstName = session[:first_name]

  matches = params[:url].match(/^http:\/\/productdata.zanox.com\/((exportservice\/.*\/rest\/)|(.*)Format.aspx\?partnerCode=)(\d+C\d+)(.{4}).*/)
  if(!matches)
    @stored = false
  else
    session[:str_replacement] = matches[4]
    session[:url]=params[:url]
    @url=session[:url]
    @str_replacement = session[:str_replacement]
    @stored = true
  end

  haml :input
end

get '/links' do
  @connected = session[:connected]
  @userId = session[:user_id]
  @userName = session[:user_name]
  @firstName = session[:first_name]
  @admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :programId => 430.to_s, :adspaceId => 205575.to_s)
  haml :links
end

get '/adspaces' do
  @connected = session[:connected]
  @userId = session[:user_id]
  @userName = session[:user_name]
  @firstName = session[:first_name]
  @adspaces = Zanox::Adspace.find(:all)
  haml :adspaces
end


post '/adspaces' do
  session[:adspaces]=''
  params.each do |param|
    keyValue = param[0].split('_')
    if(keyValue[1]=='adspace')
      session[:adspaces]+= param[1] + ','
    end
  end
  @connected = session[:connected]
  @userId    = session[:user_id]
  @userName  = session[:user_name]
  @firstName = session[:first_name]
  @adspaces  = Zanox::Adspace.find(:all)
  @selectedAdspaces = session[:adspaces]
  haml :adspaces
end


get '/logout' do
  @connected = session[:connected] = false
  haml :index
end
