# Message definitions for KennySync nodes

class Message

  attr_accessor :type
  attr_accessor :id
  attr_accessor :value

  def initialize(type, id, value)
    self.type = type
    self.id = id
    self.value = value
  end

  def to_s
    return "#{self.type.to_s} #{self.id} #{self.value}"
  end

  def to_sendable
    return self.to_s + "\n"
  end

  def self.parse(str)
    parts = str.split

    if parts.length == 0
      return nil
    end

    type = parts[0].to_sym
    if parts.length > 1
      id = parts[1].to_i
    end
    if parts.length > 2
      value = parts[2..-1].join(" ")
    end

    case type
    when :kennysync
      return SyncMessage.new
    when :info
      return InfoMessage.new(value)
    when :broadcast
      return BroadcastMessage.new(value)
    else
      return Message.new(type, id, value)
    end
  end

  def on_receive(conn)
    conn.send_data("Parsed message of type: #{self.type.to_s}\n")
    conn.log_event("message (#{self.type.to_s})")
  end

end

class SyncMessage < Message
  def initialize
    super(:kennysync, nil, nil)
  end

  def to_s
    return "kennysync"
  end

  def on_receive(conn)
    conn.validated = true
    conn.log_event("validate")
  end
end

class InfoMessage < Message
  def initialize(msg)
    super(:info, 0, msg)
  end

  def on_receive(conn)
    conn.log_event("info: #{self.value}")
  end
end

class BroadcastMessage < Message
  def initialize(msg)
    super(:broadcast, 0, msg)
  end

  def on_receive(conn)
    conn.log_event("broadcast: #{self.value}")
    $connections.each do |conn2|
      conn2.send_data(InfoMessage.new(self.value).to_sendable)
    end
  end
end

# The identifer for proprosal messsages
class ProposalID
  include Comparable
  attr_reader :port, :time

  def initialize(port)
    @port = port
    @time = Time.now
  end

  def to_s
    return "#{self.time.to_s} @ #{self.port}"
  end

  def <=>(other)
    if self.time == other.time
      self.port <=> other.port
    else
      self.time <=> other.time
    end
  end
end

# Paxos messages
class PrepareMessage < Message
  def initialize(msg)
    super(:prepare, ProposalID.new($nodeID), msg)
  end

  # If this message has a larger ID than the current highest promise,
  # then make this the new promise and respond with such.
  def on_receive(conn)
    if self.id > $highestPromised.id
      $highestPromised = self
      conn.send(PromiseMessage.new(self.id, $highestAccepted).to_sendable)
    end
  end
end

class PromiseMessage < Message
  # pass in the id of the message we're responding to.
  def initialize(id, msg)
    super(:promise, id, msg)
  end

  # If we receive a reponse to the proposal, increment the number of acceptances.
  # If we have enough acceptances for a quorum, we can set a value to our proposal. 
  # We can also reset our counter and ignore any more acceptances we receive for that id.
  # If any Acceptors have already accepted a proposal, 
  # we set our proposal's value to be the value of the highest numbered accepted proposal.
  # Otherwise, we can set it to anything.
  def on_receive(conn)
  end
end

class AcceptRequestMessage < Message
  def initialize(id, msg)
    super(:acceptrequest, id, msg)
  end

  # If we receive an Accept Request for proposal N, 
  # we accept it IFF we have not promised a proposal M such that M > N.
  # If we accept, set the new highestAccepted value and respond with an AcceptedMessage 
  # to the Proposer and every Learner.
  def on_receive(conn)
  end
end

class AcceptedMessage < Message
  def initialize(id, msg)
    super(:accept, id, msg)
  end

  # If we receive an Accepted message then we act as a learner and do what the request says. 
  # (i.e. update or respond)
  def on_receive(conn)
  end
end
