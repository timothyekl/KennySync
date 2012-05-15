require File.join(File.dirname(__FILE__), "listener.rb")

class VisualizingListener
  include Listener

  attr_accessor :log
  attr_accessor :buffer

  def initialize(stream)
    self.log = Logger.new(stream)
    self.log.formatter = proc do |severity, datetime, progname, msg| "#{msg}\n" end
    self.buffer = []

    EventMachine::PeriodicTimer.new(1) do
      self.log.info { self.space_line(["|"] * ($connector.size + 1)) }
    end
  end

  # listener methods

  def on_connect(conn)
    self.log.info { self.space_line(["|"] * ($connector.size + 1) + ["+"]) }
  end

  def on_disconnect(conn)
    idx = $connector.index(conn)

    self.log.info { self.space_line(["|"] * (idx + 1) + ["X"] + ["|"] * ($connector.size - idx - 1)) }

    if idx != $connector.size - 1
      # Extended disconnect - transition other lines in
      ["  /", " /", "/"].each do |sym|
        self.log.info { self.space_line(["|"] * (idx + 1) + [sym] + ["/"] * ($connector.size - idx - 2)) }
      end
    end
  end

  def on_receive(message)
    return if message.conn.nil?

    idx = $connector.index(message.conn)
    offset = 1
    if idx.nil? and message.is_a? SyncMessage
      idx = $connector.size
      offset = 0
    end
    self.log.info { "|<-------" + ("---" * (idx)) + "|" + "  |" * ($connector.size - idx - offset) + "        " + message.log_msg }
  end

  def on_send(message)
    return if message.conn.nil?

    idx = $connector.index(message.conn)
    self.log.info { "|-------" + ("---" * (idx)) + ">|" + "  |" * ($connector.size - idx - 1) + "        " + message.log_msg }
  end

  def on_state_change(description, conn)
    self.log.info { self.space_line(["$"] + ["|"] * $connector.size) + "        " + description }
  end

  # printing & format methods

  def log_line
    if self.buffer.empty?
      return 
    end
  end

  def space_line(syms)
    return "" if syms.empty?

    return syms[0] + "        " + syms[1, syms.length].join("  ")
  end

end
