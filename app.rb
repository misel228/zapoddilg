require 'rubygems'
require 'sinatra'
require 'haml'
require 'zanox'
require '../zapoddilg_keys'


configure do
  $zanox_connect_link='https://auth.zanox-affiliate.de/login?appid=1A954C44E978336DABF8'
  Zanox::API.public_key = PUBLIC_KEY
  Zanox::API.secret_key = SECRET_KEY
end

get '/' do
  if Zanox::API::Session.connect_id.nil?
    @connected = false
  else
    @connected = true
  end
  haml :index
end

get '/auth' do
  #login here
  if(params[:authtoken]) 
    Zanox::API::Session.new(params[:authtoken])
    redirect '/apps'
  else 
    @error = 'Login unsuccessful - could not get session'
    haml :nosuccess
  end
end

get '/apps' do
  #Zanox::API::
  unless Zanox::API::Session.connect_id.nil?
    @programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed')
#    @page = (params[:page] || 1).to_i
#    @admedia = Zanox::Admedium.find(:all , :items=>5, :page=> @page-1, :purpose=>'productDeeplink', :partnerShip => 'direct')
#    @admedia.inspect
  end
  unless @programApplications.nil?
    @connected = true
    haml :admedia
  else
    @error = 'Admedia could not be accessed'
    haml :nosuccess
  end
end

get '/input' do
  haml :input
end

post '/input' do
  @url = params[:url]
  haml :input
end
