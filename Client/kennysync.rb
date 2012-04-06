#!/usr/bin/env ruby
#
# KennySync client. Needs Ruby 1.9. See README.md.
#
# Dedicated, as always, to Kenny.

require 'socket'

# Increment this number when network-protocol compatibility changes
VERSION = 1

# Port to start listening/scanning at
DEFAULT_PORT = 7115

# Primary node class
class Node

  attr_accessor :listen_port
  attr_accessor :serv_sock
  attr_accessor :connections

  def initialize
    super
    
    self.listen_port = DEFAULT_PORT

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

  def connect_other_nodes
    self.connections = []
    DEFAULT_PORT.upto(self.listen_port - 1).each do |p|
      Thread.start(TCPSocket.new('localhost', p)) do |sock|
        version_string = "kennysync #{VERSION}"
        sock.puts version_string
        s = sock.gets.chomp
        if s == version_string
          self.connections << sock
          puts "Connected on port #{p}"
        else
          puts "Version mismatch on port #{p}"
        end
      end
    end
  end

  def run
    self.connect_other_nodes

    loop do
      Thread.start(self.serv_sock.accept) do |client|
        version_string = "kennysync #{VERSION}"
        s = client.gets.chomp
        client.puts version_string
        if s == version_string
          self.connections << client
          puts "Accepted connection from client"
        else
          puts "Version mismatch from client"
        end
      end
    end
  end

end

Node.new.run
