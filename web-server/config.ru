require 'rack/websocket'
require 'rack/contrib'

require './app'
require './web_socket_app'

$stdout.sync = true

map '/ws' do
  run WebSocketApp.new
end

map '/' do
  use Rack::Deflater
  use Rack::StaticCache, :urls => ["/img", "/css", "/js"], :root => "public"

  run App
end
