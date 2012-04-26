require File.join(File.dirname(__FILE__), 'listener.rb')

class LogListener
  include Listener
  
  attr_accessor :log

  def initialize(logger)
    self.log = logger
  end

  def on_connect(conn)
    self.log_event("connect (#{$connections.length} total)", conn)
  end

  def on_message(message)
    to_log = message.log_msg

    if to_log.respond_to?(:each)

      to_log.each do |m|
        self.log_event(m, message.conn)
      end

    else
      self.log_event(to_log, message.conn)
    end
  end

  def on_disconnect(conn)
    self.log_event("disconnect (#{$connections.length} total)", conn)
  end

  def log_event(msg, conn = nil, lvl = Logger::INFO)
    if conn.nil?
      self.log.add(lvl, nil, "unknown") { msg }
    else
      conn.populate_variables
      vstr = conn.validated ? "+" : " "
      ip = conn.ip || "0.0.0.0"
      port = conn.port || "0"
      self.log.add(lvl, nil, "#{vstr}#{ip}:#{port}") { msg }
    end
  end

end
