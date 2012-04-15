#!/usr/bin/env ruby

require 'eventmachine'
require 'pp'
require 'socket'

class KennySync < EventMachine::Connection

  attr_accessor :port
  attr_accessor :ip
  attr_accessor :validated

  #
  # EventMachine methods
  #
  def post_init
    self.log_event("connect")
    self.send_data("kennysync\n")
  end

  def receive_data(data)
    if data =~ /kennysync/
      self.validated = true
      self.log_event("validate")
    else
      self.send_data("Got data: #{data}")
      self.log_event("data: #{data}")
    end
  end

  def unbind
    self.log_event("disconnect")
  end

  #
  # Helpers
  #
  def populate_variables
    if self.port.nil? or self.ip.nil?
      if !self.get_peername().nil?
        self.port, self.ip = Socket.unpack_sockaddr_in(self.get_peername())
      end
    end

    if self.validated.nil?
      self.validated = false
    end
  end

  def log_event(msg)
    self.populate_variables

    vstr = self.validated ? "+" : " "
    ip = self.ip || "0.0.0.0"
    port = self.port || "0"
    puts "[#{vstr}#{ip}:#{port}] #{msg}"
  end

end

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
