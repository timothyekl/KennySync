require 'eventmachine'
require 'pp'
require 'socket'

require './messages.rb'

# Global object instances
$listeners = []

$type = nil # either :paxos, :input, or :output

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
  attr_accessor :uuid # this is the uuid of the node on the other end of this connection
  attr_accessor :validated
  attr_accessor :type # type of the node on the other end

  #
  # EventMachine methods
  #
  def post_init
    $type = self.node_type
    self.dispatch_event(:on_connect, [self])
    self.send_data(SyncMessage.new($uuid).to_sendable)
  end

  def node_type
    return :paxos
  end

  def receive_data(data)
    msg = Message.parse(data, self)
    return if msg.nil?

    msg.on_receive()
    self.dispatch_event(:on_receive, [msg])

    $connector.add(self.uuid, self) if msg.is_a? SyncMessage
  end

  def unbind
    self.dispatch_event(:on_disconnect, [self])
    $connector.remove(self.uuid)
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

class InputNode < KennySync
  def node_type
    return :input
  end
end

class OutputNode < KennySync
  def node_type
    return :output
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
