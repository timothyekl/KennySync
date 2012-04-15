require 'eventmachine'
require 'pp'
require 'socket'

require './messages.rb'

$connections = []

class KennySync < EventMachine::Connection

  attr_accessor :port
  attr_accessor :ip
  attr_accessor :validated

  #
  # EventMachine methods
  #
  def post_init
    $connections << self
    self.log_event("connect (#{$connections.length} total)")
    self.send_data(SyncMessage.new.to_sendable)
  end

  def receive_data(data)
    msg = Message.parse(data)
    if msg.nil?
      self.log_event("ill-formed message: #{data}")
      return
    end

    case msg.type
    when :kennysync
      self.validated = true
      self.log_event("validate")
    else
      self.send_data("Parsed message of type: #{msg.type.to_s}\n")
      self.log_event("message (#{msg.type.to_s})")
    end
  end

  def unbind
    $connections.delete(self)
    self.log_event("disconnect (#{$connections.length} total)")
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
