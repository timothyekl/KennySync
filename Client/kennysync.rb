require 'eventmachine'
require 'pp'
require 'socket'

require './messages.rb'

# Global object instances
$connections = []
$listeners = []

# Paxos protocol info
$highestAccepted = nil
$highestPromised = 0
$acceptances = []
$currentProposalID = nil

class KennySync < EventMachine::Connection

  attr_accessor :port
  attr_accessor :ip
  attr_accessor :validated

  #
  # EventMachine methods
  #
  def post_init
    $connections << self
    self.dispatch_event(:on_connect, [self])
    self.send_data(SyncMessage.new.to_sendable)
  end

  def receive_data(data)
    msg = Message.parse(data, self)
    self.dispatch_event(:on_message, [msg])
    return if msg.nil?
    msg.on_receive()
  end

  def unbind
    $connections.delete(self)
    self.dispatch_event(:on_disconnect, [self])
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

  def dispatch_event(evt, args)
    $listeners.each do |listener|
      if listener.respond_to? evt
        listener.send(evt, *args)
      end
    end
  end

end

class KennyCommand < EventMachine::Connection

  include EventMachine::Protocols::LineText2

  def receive_line(data)
    # Parse data into message
    msg = Message.parse(data)

    # Send message to all nodes
    $connections.each do |conn|
      conn.send_data msg.to_sendable
    end
  end

end
