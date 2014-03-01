require 'rack/websocket'
require 'json'

class WebSocketApp < Rack::WebSocket::Application

    def initialize(options = {})
        super
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
        puts error.stacktrace.join('\n')
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
        data = {
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

        send_data(data.to_json)
    end
end
