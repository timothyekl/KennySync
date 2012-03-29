#!/usr/bin/env ruby
#
# KennySync client. Needs Ruby 1.9. See README.md.
#
# Dedicated, as always, to Kenny.

require 'socket'

class Node

  attr_accessor :listen_port
  attr_accessor :serv_sock

  def initialize
    super
    
    self.listen_port = 7115

    self.serv_sock = TCPServer.new("", self.listen_port)
    puts "Listening on port #{self.listen_port}"
  end

  def start
    result = select([self.serv_sock], nil, nil, nil)
  end

end

Node.new.start
