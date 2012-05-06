require 'eventmachine'
require 'pp'
require 'socket'

require './messages.rb'

# Global object instances
$listeners = []

# Paxos protocol info
$highestAccepted = nil
$highestPromised = 0
$acceptances = []
$numAcceptances = 0
$currentProposalID = nil
$acceptedTracker = {}

class KennySync < EventMachine::Connection

  attr_accessor :port
  attr_accessor :ip
  attr_accessor :validated

  #
  # EventMachine methods
  #
  def post_init
    self.dispatch_event(:on_connect, [self])
    self.send_data(SyncMessage.new.to_sendable)
  end

  def receive_data(data)
    msg = Message.parse(data, self)
    self.dispatch_event(:on_receive, [msg])
    return if msg.nil?
    msg.on_receive()
  end

  def unbind
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
    ($listeners + [$connector]).each do |listener|
      if listener.respond_to? evt
        listener.send(evt, *args)
      end
    end
  end

  def uuid
    # The UUID of the machine on the other end
    # TODO this should be something else
    
    self.populate_variables
    return self.port
  end

end

class KennyCommand < EventMachine::Connection

  include EventMachine::Protocols::LineText2

  def receive_line(data)
    # Parse data into message
    msg = Message.parse(data)

    # Send message to all nodes
    $connector.each do |conn|
      conn.send_data msg.to_sendable
    end
  end

end
