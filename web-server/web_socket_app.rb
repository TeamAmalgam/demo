require 'rack/websocket'
require 'json'
require 'em-hiredis'
require 'yaml'

class WebSocketApp < Rack::WebSocket::Application

        GIA_TEST_DATA = {
            "start_time" => Time.now(),
            "finished" => false,
            "pareto_points_found" => 2,
            "pareto_points" => [
                {
                    "cost" => 10,
                    "performance" => 12
                },
                {
                    "cost" => 11,
                    "performance" => 13
                }
            ]
        }

        CGIA_TEST_DATA = {
            "start_time" => Time.now(),
            "finished" => false,
            "pareto_points_found" => 3,
            "pareto_points" => [
                {
                    "cost" => 10,
                    "performance" => 12
                },
                {
                    "cost" => 11,
                    "performance" => 13
                },
                {
                    "cost" => 12,
                    "performance" => 14
                }
            ]
        }

        PGIA_TEST_DATA = {
            "start_time" => Time.now(),
            "finished" => false,
            "pareto_points_found" => 4,
            "pareto_points" => [
                {
                    "cost" => 10,
                    "performance" => 12
                },
                {
                    "cost" => 11,
                    "performance" => 13
                },
                {
                    "cost" => 12,
                    "performance" => 14
                },
                {
                    "cost" => 13,
                    "performance" => 15
                }
            ]
        }

        MODEL_TEST_DATA = {
            "model_name" => "test_model.als",
            "total_pareto_points" => 10,
            "metrics" => [
                "cost",
                "performance"
            ],
            "metric_directions" => {
                "cost" => "min",
                "performance" => "max"
            },
            "metric_maximums" => {
                "cost" => 20,
                "performance" => 20
            }
        }

        TEST_DATA = {
            "command" => "refresh",
            "body" => MODEL_TEST_DATA.merge({
                "gia" => GIA_TEST_DATA,
                "cgia" => CGIA_TEST_DATA,
                "pgia" => PGIA_TEST_DATA
            })
        }

    def initialize(options = {})
        super
        EM.next_tick{
          @redis = EM::Hiredis.connect

          @redis.get('model') do |value|
            @redis.set('model', MODEL_TEST_DATA.to_yaml) if value.nil?
          end

          @redis.get('gia') do |value|
            @redis.set('gia', GIA_TEST_DATA.to_yaml) if value.nil?
          end

          @redis.get('cgia') do |value|
            @redis.set('cgia', CGIA_TEST_DATA.to_yaml) if value.nil?
          end

          @redis.get('pgia') do |value|
            @redis.set('pgia', PGIA_TEST_DATA.to_yaml) if value.nil?
          end
        }
    end

    def on_open(env)
        close_websocket unless env['REQUEST_PATH'] == '/ws'
        puts "Client connected"

        @redis.pubsub.subscribe("model") do |message|
            on_refresh
        end

        @redis.pubsub.subscribe("gia") do |message|
            on_refresh
        end

        @redis.pubsub.subscribe("cgia") do |message|
            on_refresh
        end

        @redis.pubsub.subscribe("pgia") do |message|
            on_refresh
        end
    end

    def on_close(env)
        puts "Client disconnected"
    end

    def on_error(env, error)
        puts error.inspect
        puts error.backtrace.join('\n')
    end

    def on_message(env, msg) 
        puts "Raw message: " + msg
        msg = JSON.parse(msg);
        puts "Received message: " + msg.inspect

        case msg["command"]
            when "refresh" then on_refresh
            when "start" then on_start
            when "stop" then on_stop
        end
    end

    def on_refresh
        @redis.get("model") do |model|
        @redis.get("gia") do |gia|
        @redis.get("cgia") do |cgia|
        @redis.get("pgia") do |pgia|
            value = YAML.load(model)
            value = value.merge({
                "gia" => YAML.load(gia),
                "cgia" => YAML.load(cgia),
                "pgia" => YAML.load(pgia)
            })

            command = {
                "command" => "refresh",
                "body" => value
            }

            send_data(command.to_json)
        end
        end
        end
        end
    end
end
