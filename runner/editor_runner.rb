#!/usr/bin/env ruby

require 'rubygems'
require 'hiredis'
require 'redis'
require 'tmpdir'
require 'fileutils'
require 'yaml'

$algorithm = ARGV[0]
$executable_location = ARGV[1]

raise "Bad Arguments" if $algorithm.nil? || $executable_location.nil?

$executable_location = File.absolute_path($executable_location)

$redis = Redis.new

$running = false

def run(data)
      redis = Redis.new
      data = YAML.load(data)

      # Create a temporary directory.
      Dir.mktmpdir do |dir|
          model_contents = <<-EOS
abstract sig Contractor {
  value_units : set ValueUnit,
  experience_values : ValueUnit -> Int,
  financial_stability_values : ValueUnit -> Int
}

abstract sig ValueUnit {
  contractor : one Contractor,
  experience_value : Int,
  financial_stability_value : Int
}
{
  experience_value = contractor.experience_values[this]
  financial_stability_value = contractor.financial_stability_values[this]
}

one sig VU1, VU2, VU3, VU4, VU5 extends ValueUnit {

}

one sig Bob extends Contractor {
}
{
  experience_values = 
    VU1 -> #{data["bob"]["experience"]["vu1"].to_i} +
    VU2 -> #{data["bob"]["experience"]["vu2"].to_i} +
    VU3 -> #{data["bob"]["experience"]["vu3"].to_i} +
    VU4 -> #{data["bob"]["experience"]["vu4"].to_i} +
    VU5 -> #{data["bob"]["experience"]["vu5"].to_i}

  financial_stability_values =
    VU1 -> #{data["bob"]["financial"]["vu1"].to_i} +
    VU2 -> #{data["bob"]["financial"]["vu2"].to_i} +
    VU3 -> #{data["bob"]["financial"]["vu3"].to_i} +
    VU4 -> #{data["bob"]["financial"]["vu4"].to_i} +
    VU5 -> #{data["bob"]["financial"]["vu5"].to_i}
}

one sig Wendy extends Contractor {
}
{
  experience_values = 
    VU1 -> #{data["wendy"]["experience"]["vu1"].to_i} +
    VU2 -> #{data["wendy"]["experience"]["vu2"].to_i} +
    VU3 -> #{data["wendy"]["experience"]["vu3"].to_i} +
    VU4 -> #{data["wendy"]["experience"]["vu4"].to_i} +
    VU5 -> #{data["wendy"]["experience"]["vu5"].to_i}

  financial_stability_values =
    VU1 -> #{data["wendy"]["financial"]["vu1"].to_i} +
    VU2 -> #{data["wendy"]["financial"]["vu2"].to_i} +
    VU3 -> #{data["wendy"]["financial"]["vu3"].to_i} +
    VU4 -> #{data["wendy"]["financial"]["vu4"].to_i} +
    VU5 -> #{data["wendy"]["financial"]["vu5"].to_i}
}

one sig Problem {
  experience_total : Int,
  financial_stability_total : Int
}
{
  experience_total = (sum vu : ValueUnit | vu.experience_value)
  financial_stability_total = (sum vu : ValueUnit | vu.financial_stability_value)
}

fact { all vu : ValueUnit | one cm : Contractor | vu in cm.value_units }
fact { value_units = ~(contractor) }

inst config {
  10 Int
}

objectives o_global {
  maximize Problem.experience_total,
  maximize Problem.financial_stability_total
}

pred show {
}

run show for config optimize o_global
          EOS

          original_directory = FileUtils.pwd
          FileUtils.cd(dir)

          puts "Entered temporary directory."

          FileUtils.cp($executable_location, File.join(dir, "moolloy.jar"))

          File.open(File.join(dir, "model.als"), "w") do |file|
            file.puts(model_contents)
          end

          puts "Copied required files."

          # About to run, so we need to set up the redis data.
          data = {
              "start_time" => Time.now(),
              "finished" => false,
              "errored" => false,
              "pareto_points_found" => 0,
              "pareto_points" => [
              ],
              "solutions" => [
              ]
          }

          redis.set("editor-results", data.to_yaml)
          redis.publish("editor-results", nil)

          IO.popen(["java", "-jar", "./moolloy.jar", "-s", "--MooAlgorithm=#{$algorithm.upcase}", "./model.als", :err => [:child, :out]]) do |io|
              io.each_line do |line|
                  # Is this line saying we found a solution?
                  match = /.*Found a solution.*\[([^\]]*)\].*/.match(line)
                  if match
                      metrics = match[1].split(/,\s+/)
                      data["solutions"] << {
                          "cost" => metrics[0],
                          "performance" => metrics[1]
                      }

                      redis.set("editor-results", data.to_yaml)
                      redis.publish("editor-results", nil)

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
                      data["pareto_points_found"] += 1

                      redis.set("editor-results", data.to_yaml)
                      redis.publish("editor-results", nil)

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

          redis.set("editor-results", data.to_yaml)
          redis.publish("editor-results", nil)

          FileUtils.cd(original_directory)
      end
end

$redis.subscribe('editor-run') do |on|
  on.message do |channel, data|
    unless $running
      $running = true
      run(data)
      $running = false
    end
  end
end
