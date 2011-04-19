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
  haml :index
end

get '/auth' do
  #login here
  if(params[:authtoken])
    Zanox::API::Session.new(params[:authtoken])
#     puts Zanox::Session.getUiUrl()
    session[:connected]=true
    #session[:ui_url] = 
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
       partnerCodes += deeplink.trackingLinks.trackingLink.ppc.scan(/^.*\/ppc\/\?(\d+C\d+)&.*/);
     end

  end
  unless deeplinks.nil?
    @connected = session[:connected]
    @deeplinks = deeplinks
    @partnerCodes = partnerCodes
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
    @ui_url = Zanox::Connect.ui_url()
  end
  @url=session[:url]
  haml :input
end

post '/input' do
  @connected = session[:connected]
  session[:url]=params[:url]
  @url=session[:url]
  @stored = true
  haml :input
end

get '/links' do
  @connected = session[:connected]
  @admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :programId => 430.to_s, :adspaceId => 205575.to_s)
  haml :links
end

get '/adspaces' do
  @connected = session[:connected]
  @adspaces = Zanox::Adspace.find(:all)
  haml :adspaces
end

get '/logout' do
  @connected = session[:connected] = false
  haml :index
end
