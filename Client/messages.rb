# Message definitions for KennySync nodes

class Message

  attr_accessor :type
  attr_accessor :id
  attr_accessor :value
  attr_accessor :conn

  def initialize(type, id, value, conn = nil)
    self.type = type
    self.id = id
    self.value = value
    self.conn = conn
  end

  def to_s
    return "#{self.type.to_s} #{self.id} #{self.value}"
  end

  def to_sendable
    return self.to_s + "\n"
  end

  def self.parse(str, conn = nil)
    clsmap = {:kennysync => [SyncMessage, [:id, :value, :conn]],
              :info => [InfoMessage, [:value, :conn]],
              :broadcast => [BroadcastMessage, [:value, :conn]],
              :node => [NodeMessage, [:value, :conn]],
              :prepare => [PrepareMessage, [:value, :id, :conn]],
              :promise => [PromiseMessage, [:id, :value, :conn]],
              :acceptrequest => [AcceptRequestMessage, [:id, :value, :conn]],
              :accepted => [AcceptedMessage, [:id, :value, :conn]]}

    parts = str.split

    if parts.length == 0
      return nil
    end

    type = parts[0].to_sym
    args = {}
    if parts.length > 1
      args[:id] = parts[1].to_i
    end
    if parts.length > 2
      args[:value] = parts[2..-1].join(" ")
    end

    args[:conn] = conn

    return clsmap[type][0].new(*(clsmap[type][1].map{|s| args[s]}))
  end

  def on_receive
    self.conn.send_data("Parsed message of type: #{self.type.to_s}\n")
  end

  def log_msg
    return "message (#{self.type.to_s})"
  end

  def state_changed(description)
    self.conn.dispatch_event(:on_state_change, [description, self.conn])
  end

  def has_learned
    if $acceptedTracker[[self.id, self.value]] > $connector.size.to_f / 2
      self.state_changed("learned the value of #{self.value} on id #{self.id}")
    end
  end

  def log(msg, lvl = nil)
    args = [msg, self.conn]
    args << lvl if !lvl.nil?
    self.conn.dispatch_event(:on_log, args)
  end
end

class NodeMessage < Message
  def initialize(addr, conn = nil)
    super(:node, nil, addr, conn)
  end

  def on_receive
    self.log("Received notification of node at #{self.value}", Logger::DEBUG)
    
    addr = self.value
    parts = addr.split(":")
    return if parts.size != 2

    ip = parts[0]
    port = parts[1].to_i
    return if port <= 0 || port >= 65536

    if !$connector.include_conn_to?(ip, port)
      self.log("Connecting to #{ip}:#{port} as result of notification", Logger::DEBUG)
      EventMachine::connect(ip, port, KennySync) 
    end
  end

  def to_s
    # word "at" required due to parsing specifics
    # it has no actual meaning
    return "node at #{self.value}"
  end

  def log_msg
    return "node #{self.value}"
  end
end

class SyncMessage < Message
  def initialize(port, uuid, conn = nil)
    super(:kennysync, port, uuid, conn)
  end

  def to_s
    # in this context, id=listening port and value=uuid string
    return "kennysync #{self.id} #{self.value}"
  end

  def on_receive
    self.conn.validated = true
    self.conn.remote_listen_port = self.id
    self.conn.uuid = self.value

    # Send node list
    self.log("Received sync message, sending node list", Logger::DEBUG)
    $connector.each do |c|
      self.log("Sending node notification: #{c.ip}:#{c.remote_listen_port}", Logger::DEBUG)
      self.conn.send_data(NodeMessage.new("#{c.ip}:#{c.remote_listen_port}").to_sendable)
    end
  end

  def log_msg
    return "validate"
  end
end

class InfoMessage < Message
  def initialize(msg, conn = nil)
    super(:info, 0, msg, conn)
  end

  def on_receive
    # Nothing
  end

  def log_msg
    return "info: #{self.value}"
  end
end

class BroadcastMessage < Message
  def initialize(msg, conn = nil)
    super(:broadcast, 0, msg, conn)
  end

  def on_receive
    $connector.each do |c|
      msg = InfoMessage.new(self.value)
      msg.conn = c
      c.send_data(msg.to_sendable)
      c.dispatch_event(:on_send, [msg])
    end
  end

  def log_msg
    return "broadcast: #{self.value}"
  end
end

#
# Paxos messages
#

class PrepareMessage < Message
  def initialize(msg, id = 0, conn = nil)
    if id == 0
      t = Time.now
      id = t.to_i.to_s.rjust(20,'0')
      id = id.concat(t.nsec.to_s.rjust(20,'0'))
      id = id.concat($nodeID.to_s.rjust(10,'0'))
      id = id.to_i
    end
    super(:prepare, id, msg, conn)
    $currentProposalID = id
    $acceptances = [[0,msg]]
    $numAcceptances = 0
  end

  # If this message has a larger ID than the current highest promise,
  # then make this the new promise and respond with such.
  def on_receive
    if self.id > $highestPromised
      self.state_changed("promise granted for #{self.id}")
      $highestPromised = self.id
      msg = PromiseMessage.new(self.id, $highestAccepted)
      msg.conn = self.conn
      self.conn.send_data(msg.to_sendable)
      self.conn.dispatch_event(:on_send, [msg])
    end
  end

  def log_msg
    return "prepare: #{self.to_s}"
  end
end

class PromiseMessage < Message
  # pass in the id of the message we're responding to.
  def initialize(id, msg, conn = nil)
    super(:promise, id, msg, conn)
  end

  # If we receive a reponse to the proposal, attach it to our list of acceptances.
  # If we have enough acceptances for a quorum, we can set a value to our proposal. 
  # We can also reset our accumulator and ignore any more acceptances we receive for that id.
  # If any Acceptors have already accepted a proposal, 
  # we set our proposal's value to be the value of the highest numbered accepted proposal.
  # Otherwise, we can set it to anything.
  def on_receive
    if self.id == $currentProposalID
      $numAcceptances += 1
      if not self.value.nil?
        $acceptances.push(eval(self.value)) # self.value is of the form [id,val]
      end
      self.state_changed("promise recorded for #{self.id} with value #{self.value}")
      if $numAcceptances > $connector.size.to_f / 2
        bestVal = $acceptances.max_by {|x| x[0]} [1] # defaults to nil
        self.state_changed("quorum reached for #{self.id} with value #{bestVal}")
        $connector.each do |c|
          msg = AcceptRequestMessage.new($currentProposalID, bestVal)
          msg.conn = c
          c.send_data(msg.to_sendable)
          c.dispatch_event(:on_send, [msg])
        end
      end
    end
  end

  def log_msg
    return "promise: #{self.to_s}"
  end
end

class AcceptRequestMessage < Message
  def initialize(id, msg, conn = nil)
    super(:acceptrequest, id, msg, conn)
  end

  # If we receive an Accept Request for proposal N, 
  # we accept it IFF we have not promised a proposal M such that M > N.
  # If we accept, set the new highestAccepted value and respond with an AcceptedMessage 
  # to the Proposer and every Learner.
  def on_receive
    if self.id >= $highestPromised
      self.state_changed("accept request granted for #{self.id} with value #{self.value}")
      # record that we've accepted it
      $highestAccepted = [self.id, self.value]
      if not $acceptedTracker.has_key?([self.id, self.value])
        $acceptedTracker[[self.id, self.value]] = 1
      else
        $acceptedTracker[[self.id, self.value]] += 1
      end
      $connector.each do |c|
        msg = AcceptedMessage.new(self.id, self.value)
        msg.conn = c
        c.send_data(msg.to_sendable)
        c.dispatch_event(:on_send, [msg])
      end
      self.has_learned # we might be done
    end
  end

  def log_msg
    return "accept request: #{self.to_s}"
  end
end

class AcceptedMessage < Message
  def initialize(id, msg, conn = nil)
    super(:accepted, id, msg, conn)
  end

  # If we receive an Accepted message then we act as a learner and do what the request says. 
  # (i.e. update or respond)
  def on_receive
    # record the receipt of this acceptance
    if not $acceptedTracker.has_key?([self.id, self.value])
      $acceptedTracker[[self.id, self.value]] = 1
    else
      $acceptedTracker[[self.id, self.value]] += 1
    end
    self.has_learned
  end

  def log_msg
    return "accepted: #{self.to_s}"
  end
end

