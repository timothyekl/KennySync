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
require './listeners/log.rb'

START_PORT = 7115

options = {:log_level => :info}
OptionParser.new do |opts|
  opts.banner = "Usage: run.rb [options]"

  opts.on("-d", "--debug-level LEVEL", [:fatal, :error, :warn, :info, :debug], "Logging threshold") do |d|
    options[:log_level] = d
  end

  opts.on("-l", "--log FILE", "Log file") do |f|
    if f == "stdout"
      options[:log_file] = STDOUT
    else
      options[:log_file] = f
    end
  end

  opts.on("-V", "--visualization [STREAM]", "Visualize activity") do |v|
    if v == "stdout"
      options[:visualization] = STDOUT
    else
      options[:visualization] = v
    end
  end
end.parse!

log_listener = LogListener.new(options[:log_file], options[:log_level])
$listeners << log_listener

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

  # Kind of a hack, but we want to unconditionally log listen port
  log_listener.log.info('general') { "Listening on port #{listen_port}" }
  
  # Each node needs a unique identifer. We're using the port number as a cheap hack.
  $nodeID = listen_port

  # Now connect to other nodes
  START_PORT.upto(listen_port - 1).each do |port|
    EventMachine::connect("127.0.0.1", port, KennySync)
  end

  EventMachine::open_keyboard(KennyCommand)
}
