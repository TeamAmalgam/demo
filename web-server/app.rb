require "sinatra/base"
require "sinatra/link_header"

require_relative "helpers/init"

class App < Sinatra::Base
  helpers Sinatra::LinkHeader

  get '/' do
    erb :"index"
  end

  get '/race' do
    erb :"race"
  end

  get '/editor' do
    erb :"editor"
  end
end
