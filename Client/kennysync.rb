#!/usr/bin/env ruby
#
# KennySync client. Needs Ruby 1.9. See README.md.
#
# Dedicated, as always, to Kenny.

require 'socket'

# Increment this number when network-protocol compatibility changes
VERSION = 1

# Primary node class
class Node

  attr_accessor :listen_port
  attr_accessor :serv_sock

  def initialize
    super
    
    self.listen_port = 7115

    while self.listen_port < 65536
      begin
        self.serv_sock = TCPServer.new("", self.listen_port)
        break
      rescue Exception => e
        self.listen_port += 1
      end
    end

    if self.serv_sock.nil?
      raise "Could not establish TCP socket"
    else
      puts "Listening on port #{self.listen_port}"
    end
  end

  def start
    result = select([self.serv_sock], nil, nil, nil)
  end

end

Node.new.start
