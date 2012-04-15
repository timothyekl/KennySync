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
      self.port, self.ip = Socket.unpack_sockaddr_in(self.get_peername())
    end

    if self.validated.nil?
      self.validated = false
    end
  end

  def log_event(msg)
    self.populate_variables

    vstr = self.validated ? "+" : " "
    puts "[#{vstr}#{self.ip}:#{self.port}] #{msg}"
  end

end

START_PORT = 7115

EventMachine::run {
  port = START_PORT
  listening = false
  while not listening and port < 65536
    begin
      EventMachine::start_server("127.0.0.1", port, KennySync)
      listening = true
    rescue
      port += 1
    end
  end
  puts "Listening on port #{port}"
}
