#!/usr/bin/env ruby
#
# This file is the main launcher for KennySync, a Ruby implementation
# of the Paxos conflict-resolution protocol.
#
# Dedicated, as always, to Kenny.

require 'eventmachine'
require 'logger'
require 'optparse'

require './kennysync.rb'

START_PORT = 7115

$log = Logger.new(STDOUT)
$log.formatter = proc do |severity, datetime, progname, msg|
  "[#{progname}] #{msg}\n"
end

options = {:log_level => :info}
OptionParser.new do |opts|
  opts.banner = "Usage: run.rb [options]"

  opts.on("-d", "--debug-level LEVEL", [:fatal, :error, :warn, :info, :debug], "Logging threshold") do |d|
    options[:log_level] = d
  end
end.parse!
$log.level = {:fatal => Logger::FATAL,
              :error => Logger::ERROR,
              :warn => Logger::WARN,
              :info => Logger::INFO,
              :debug => Logger::DEBUG}[options[:log_level]]

EventMachine::run {
  # First start the server
  listen_port = START_PORT
  listening = false
  while not listening and listen_port < 65536
    begin
      EventMachine::start_server("127.0.0.1", listen_port, KennySync)
      listening = true
    rescue
      listen_port += 1
    end
  end
  $log.info('general') { "Listening on port #{listen_port}" }

  # Now connect to other nodes
  START_PORT.upto(listen_port - 1).each do |port|
    EventMachine::connect("127.0.0.1", port, KennySync)
  end
}
