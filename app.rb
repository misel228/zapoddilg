require 'rubygems'
require 'sinatra'
require 'haml'
require 'zanox'
require '../zapoddilg_keys'

class PartnerData
  attr_reader :adspace, :program
  def initialize(adspace, program)
    @adspace = adspace
    @program = program
  end
end

configure do
  $zanox_connect_link='https://auth.zanox-affiliate.de/login?appid=1A954C44E978336DABF8'
  Zanox::API.public_key = PUBLIC_KEY
  Zanox::API.secret_key = SECRET_KEY
  PAGE_SIZE = 50
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
    redirect '/'
  else 
    @error = 'Login unsuccessful - could not get session'
    haml :nosuccess
  end
end

get '/apps' do
  #Zanox::API::
  unless Zanox::API::Session.connect_id.nil?
    programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed', :items => PAGE_SIZE)
    myPrograms = []
    myPrograms = myPrograms + programApplications

    page = 1
    while (programApplications.size > 0) do
      programApplications = Zanox::ProgramApplication.find(:all, :status => 'confirmed', :items => PAGE_SIZE, :page => page)
      page+=1
      myPrograms=myPrograms + programApplications
    end

    partnerData = []
    myPrograms.each{ |myProgram|
      myPartnerData = PartnerData.new(myProgram.adspace.xmlattr_id, myProgram.program.xmlattr_id)
      myPartnerData.inspect
      partnerData = partnerData.push(myPartnerData)
    }
    
    deeplinks = []
    myPrograms.each do |myProgram|
      admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :program => myProgram.program.xmlattr_id, :adspace => myProgram.adspace.xmlattr_id)
      deeplinks = deeplinks + admedia
    end

    
#    @page = (params[:page] || 1).to_i
#    @admedia = Zanox::Admedium.find(:all , :items=>5, :page=> @page-1, :purpose=>'productDeeplink', :partnerShip => 'direct')
#    @admedia.inspect

  end
  unless deeplinks.nil?
    @connected = true
    @deeplinks = deeplinks
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

get '/links' do
  @admedia = Zanox::Admedium.find(:all , :purpose=>'productDeeplink', :program => 430, :adspace => 205575)
  haml :links
end
