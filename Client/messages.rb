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
    else
      return Message.new(type, id, value)
    end
  end

end

class SyncMessage < Message

  def initialize
    super(:kennysync, nil, nil)
  end

  def to_s
    return "kennysync"
  end

end
