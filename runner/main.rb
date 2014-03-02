#!/usr/bin/env ruby

require 'rubygems'
require 'hiredis'
require 'redis'

algorithm = ARGV[0]
executable_location = ARGV[1]
model_location = ARGV[2]

raise "Bad Arguments" if algorithm.nil? || executable_location.nil? || model_location.nil?
