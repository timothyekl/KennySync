#!/usr/bin/env ruby
#
# This file is the main launcher for KennySync, a Ruby implementation
# of the Paxos conflict-resolution protocol.
#
# Dedicated, as always, to Kenny.

require 'eventmachine'
require './kennysync.rb'

START_PORT = 7115

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
  puts "Listening on port #{listen_port}"

  # Now connect to other nodes
  START_PORT.upto(listen_port - 1).each do |port|
    EventMachine::connect("127.0.0.1", port, KennySync)
  end
}
