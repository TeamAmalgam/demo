#!/usr/bin/env ruby

require 'rubygems'
require 'hiredis'
require 'redis'
require 'tmpdir'
require 'fileutils'
require 'yaml'

algorithm = ARGV[0]
executable_location = ARGV[1]
model_location = ARGV[2]

raise "Bad Arguments" if algorithm.nil? || executable_location.nil? || model_location.nil?

executable_location = File.absolute_path(executable_location)
model_location = File.absolute_path(model_location)

redis = Redis.new

# Create a temporary directory.
Dir.mktmpdir do |dir|
    original_directory = FileUtils.pwd
    FileUtils.cd(dir)

    puts "Entered temporary directory."

    FileUtils.cp(executable_location, File.join(dir, "moolloy.jar"))
    FileUtils.cp(model_location, File.join(dir, "model.als"))

    puts "Copied required files."

    # About to run, so we need to set up the redis data.
    data = {
        "start_time" => Time.now(),
        "finished" => false,
        "errored" => false,
        "pareto_points_found" => 0,
        "pareto_points" => [
        ]
    }

    redis.set(algorithm, data.to_yaml)
    redis.publish(algorithm, nil)

    IO.popen(["java", "-jar", "./moolloy.jar", "-s", "./model.als", :err => [:child, :out]]) do |io|
        io.each_line do |line|
            # Is this line saying we found a solution?
            match = /.*Found a solution.*\[([^\]]*)\].*/.match(line)
            if match
                metrics = match[1].split(/,\s+/)
                puts "Found solution with metrics [#{metrics.join(", ")}]."
            end

            # Is this line saying we found a pareto point?
            match = /.*Found Pareto point.*\[([^\]]*)\].*/.match(line)
            if match
                metrics = match[1].split(/,\s+/)

                # Add the pareto point to the model.
                data["pareto_points"] << {
                    "cost" => metrics[0],
                    "performance" => metrics[1]
                }
                redis.set(algorithm, data.to_yaml)
                redis.publish(algorithm, nil)

                puts "Found pareto point with metrics [#{metrics.join(", ")}]."
            end

            # Is this line a logger error?
            if line =~ /ERROR/i
                puts line
            end
        end
    end

    data["finished"] = true
    data["finish_time"] = Time.now
    
    if $?.to_i != 0
        puts "Moolloy failed."
        data["errored"] = true
    else
        puts "Moolloy finished."
        data["errored"] = false
    end

    redis.set(algorithm, data.to_yaml)
    redis.publish(algorithm, nil)
end