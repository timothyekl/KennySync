class VisualizingListener
  include Listener

  attr_accessor :log
  attr_accessor :buffer

  def initialize(stream)
    self.log = Logger.new(stream)
    self.log.formatter = proc do |severity, datetime, progname, msg| "#{msg}\n" end
    self.buffer = []

    EventMachine::PeriodicTimer.new(1) do
      self.log.info { self.log_line }
    end
  end

  def log_line
    if self.buffer.empty?
      return self.space_line(["|"] * ($connections.length + 1))
    end
  end

  def space_line(syms)
    return "" if syms.empty?

    return syms[0] + "        " + syms[1, syms.length].join("  ")
  end

end
