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
    clsmap = {:kennysync => [SyncMessage, []],
              :info => [InfoMessage, [:value]],
              :broadcast => [BroadcastMessage, [:value]],
              :prepare => [PrepareMessage, [:value, :id]],
              :promise => [PromiseMessage, [:id, :value]],
              :acceptrequest => [AcceptRequestMessage, [:id, :value]],
              :accepted => [AcceptedMessage, [:id, :value]]}

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

    return clsmap[type][0].new(*(clsmap[type][1].map{|s| args[s]}))
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

# Paxos messages
class PrepareMessage < Message
  def initialize(msg, id=0)
    if id == 0
      t = Time.now
      id = t.to_i.to_s.rjust(20,'0')
      id = id.concat(t.nsec.to_s.rjust(20,'0'))
      id = id.concat($nodeID.to_s.rjust(10,'0'))
      id = id.to_i
    end
    super(:prepare, id, msg)
    $currentProposalID = id
    $acceptances = []
  end

  # If this message has a larger ID than the current highest promise,
  # then make this the new promise and respond with such.
  def on_receive(conn)
    conn.log_event("prepare: #{self.to_s}")
    if self.id > $highestPromised
      conn.log_event("promise granted for #{self.id}")
      $highestPromised = self.id
      msg = PromiseMessage.new(self.id, $highestAccepted).to_sendable
      conn.send_data(msg)
    end
  end
end

class PromiseMessage < Message
  # pass in the id of the message we're responding to.
  def initialize(id, msg)
    super(:promise, id, msg)
  end

  # If we receive a reponse to the proposal, attach it to our list of acceptances.
  # If we have enough acceptances for a quorum, we can set a value to our proposal. 
  # We can also reset our accumulator and ignore any more acceptances we receive for that id.
  # If any Acceptors have already accepted a proposal, 
  # we set our proposal's value to be the value of the highest numbered accepted proposal.
  # Otherwise, we can set it to anything.
  def on_receive(conn)
    conn.log_event("promise: #{self.to_s}")
    if self.id == $currentProposalID
      conn.log_event("promise recorded for #{self.id} with value #{self.value}")
      $acceptances.push [self.value] # note that here value is [id,val] or nil (highest accepted)
      if $acceptances.size > $connections.size.to_f / 2
        bestVal = $acceptances.max_by {|x| x[0]} [1] # defaults to nil
        conn.log_event("quorum reached for #{self.id} with value #{bestVal}")
        msg = AcceptRequestMessage.new($currentProposalID, bestVal)
        $connections.each {|conn2| conn2.send_data(msg.to_sendable)}
      end
    end
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
    conn.log_event("accept request: #{self.to_s}")
    if self.id >= $highestPromised
      conn.log_event("accept request granted for #{self.id} with value #{self.value}")
      $highestAccepted = [self.id, self.value]
      msg = AcceptedMessage.new(self.id, self.value)
      $connections.each {|conn2| conn2.send_data(msg.to_sendable)}
    end
  end
end

class AcceptedMessage < Message
  def initialize(id, msg)
    super(:accepted, id, msg)
  end

  # If we receive an Accepted message then we act as a learner and do what the request says. 
  # (i.e. update or respond)
  def on_receive(conn)
    conn.log_event("accepted: #{self.to_s}")
    # currently we don't actually do anything
  end
end
