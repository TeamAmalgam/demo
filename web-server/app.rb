require 'rubygems'
require 'em-websocket'
require 'sinatra/base'
require 'thin'

EventMachine.run do
  class App < Sinatra::Base
    get '/' do
      erb :"index"
    end
  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|

  end
end
