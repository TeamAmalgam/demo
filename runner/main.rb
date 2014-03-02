#!/usr/bin/env ruby

require 'rubygems'
require 'hiredis'
require 'redis'
require 'tmpdir'
require 'fileutils'
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


    io = IO.popen(["java", "-jar", "./moolloy.jar", "./model.als", :err => :out])
    io.each_line do |line|
        puts line
    end
end