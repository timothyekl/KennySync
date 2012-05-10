require File.join(File.dirname(__FILE__), 'listener.rb')

class LogListener
  include Listener
  
  attr_accessor :log

  def initialize(stream, threshold)
    log = Logger.new(stream)
    log.formatter = proc do |severity, datetime, progname, msg|
      "[#{progname}] #{msg}\n"
    end
    log.level = {:fatal => Logger::FATAL,
                  :error => Logger::ERROR,
                  :warn => Logger::WARN,
                  :info => Logger::INFO,
                  :debug => Logger::DEBUG}[threshold]

    self.log = log
  end

  def on_connect(conn)
    self.log_event("connect (#{$connector.size} total)", conn)
  end

  def on_receive(message)
    self.log_event(message.log_msg, message.conn)
  end

  def on_send(message)
    self.log_event(message.log_msg, message.conn)
  end

  def on_state_change(description, conn)
    self.log_event(description, conn)
  end

  def on_disconnect(conn)
    self.log_event("disconnect (#{$connector.size} total)", conn)
  end

  def on_log(message, conn, level)
    self.log_event(message, conn, level)
  end

  def log_event(msg, conn = nil, lvl = Logger::INFO)
    if conn.nil?
      self.log.add(lvl, nil, "general") { msg }
    else
      conn.populate_variables
      vstr = conn.validated ? "+" : " "
      ip = conn.ip || "0.0.0.0"
      port = conn.port || "0"
      self.log.add(lvl, nil, "#{vstr}#{ip}:#{port}") { msg }
    end
  end

end
