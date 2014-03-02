require 'rack/websocket'
require 'json'
require 'em-hiredis'
require 'yaml'

class WebSocketApp < Rack::WebSocket::Application

        TEST_DATA = {
            "command" => "refresh",
            "body" => {
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
                },
                "gia" => {
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
                },
                "cgia" => {
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
                },
                "pgia" => {
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
            }
        }

    def initialize(options = {})
        super
        EM.next_tick{
          @redis = EM::Hiredis.connect
          @redis.get('sample_data') do |value|
            puts TEST_DATA.to_yaml
            @redis.set('sample_data', TEST_DATA.to_yaml) if value.nil?
          end
        }
    end

    def on_open(env)
        close_websocket unless env['REQUEST_PATH'] == '/ws'
        puts "Client connected"
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
            when "refresh" then on_refresh(env, msg)
        end
    end

    def on_refresh(env, msg)
        @redis.get('sample_data') do |value|
            value = YAML.load(value)

            send_data(value.to_json)
        end
    end
end
