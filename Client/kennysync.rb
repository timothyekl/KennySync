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
$currentProposalValue = nil
$acceptedTracker = {}
$inputQueue = Queue.new
$outputQueue = Queue.new
$sessionID = 0

def addInput(val)
  $inputQueue.enq val
end

# blocking!
def getOutput
  $outputQueue.deq
end

class KennySync < EventMachine::Connection

  attr_accessor :port
  attr_accessor :ip
  attr_accessor :uuid # this is the uuid of the node on the other end of this connection
  attr_accessor :validated
  attr_accessor :remote_listen_port # this is the port the remote end is listening on

  #
  # EventMachine methods
  #
  def post_init
    self.dispatch_event(:on_connect, [self])
    self.send_data(SyncMessage.new($listen_port, $uuid).to_sendable)
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

class KennyCommand < EventMachine::Connection

  include EventMachine::Protocols::LineText2

  def receive_line(data)
    # assume data is of the form <type> <id> <value>
    # modify it to be <type> <id> <sessionID>:<value>
    tmp = data.split
    tmp[2] = "#{$sessionID}:#{tmp[2]}"
    data = tmp.join(" ")
    # Parse data into message
    msg = Message.parse(data)

    # Send message to all nodes
    $connector.each do |conn|
      conn.send_data msg.to_sendable
    end
  end

end

class KennyBoxed < EventMachine::Connection
  include EventMachine::Protocols::LineText2

  def receive_line(data)
    # data is a value to put on the input queue
    addInput(data)

    # get the next thing in the input queue so we can propose it
    if $currentProposalValue.nil? and not $inputQueue.empty?
      $currentProposalValue = $inputQueue.deq
    end
    if not $currentProposalValue.nil?
      msg = PrepareMessage.new("#{$sessionID}:#{$currentProposalValue}", 0)
      $connector.each { |conn| conn.send_data msg.to_sendable }
    end
  end
end
