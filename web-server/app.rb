require 'rubygems'
require 'em-websocket'
require 'sinatra/base'
require 'thin'

class App < Sinatra::Base
  get '/' do
    erb :"index"
  end
end
