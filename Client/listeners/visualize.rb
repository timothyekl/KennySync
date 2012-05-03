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
      self.log.info { self.space_line(["|"] * ($connections.length + 1)) }
    end
  end

  # listener methods

  def on_connect(conn)
    self.log.info { self.space_line(["|"] * $connections.length + ["+"]) }
  end

  def on_disconnect(conn)
    idx = $connections.index(conn)

    self.log.info { self.space_line(["|"] * (idx + 1) + ["X"] + ["|"] * ($connections.length - idx - 1)) }

    if idx != $connections.length - 1
      # Extended disconnect - transition other lines in
      ["  /", " /", "/"].each do |sym|
        self.log.info { self.space_line(["|"] * (idx + 1) + [sym] + ["/"] * ($connections.length - idx - 2)) }
      end
    end
  end

  def on_receive(message)
    return if message.conn.nil?

    idx = $connections.index(message.conn)
    self.log.info { "|<-------" + ("---" * (idx)) + "|" + "  |" * ($connections.length - idx - 1) + "        " + message.log_msg }
  end

  def on_send(message)
    return if message.conn.nil?

    idx = $connections.index(message.conn)
    self.log.info { "|-------" + ("---" * (idx)) + ">|" + "  |" * ($connections.length - idx - 1) + "        " + message.log_msg }
  end

  def on_state_change(description, conn)
    self.log.info { self.space_line(["$"] + ["|"] * $connections.length) + "        " + description }
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
