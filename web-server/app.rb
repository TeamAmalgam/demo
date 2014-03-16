require "sinatra/base"
require "sinatra/link_header"

require "hiredis"
require "redis"

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

  post '/editor/run' do
    redis = Redis.new
    redis.publish("editor-run", {
      "bob" => params["bob"],
      "wendy" => params["wendy"]
    }.to_yaml)
    
    redirect to("/editor")
  end
end
