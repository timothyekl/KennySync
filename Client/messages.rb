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
