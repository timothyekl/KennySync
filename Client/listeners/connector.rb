# Class that manages connections between Paxos nodes
# Should be available as a singleton in the global $connector

require File.join(File.dirname(__FILE__), 'listener.rb')

class Connector

  include Listener
  include Enumerable

  attr_accessor :connections

  def initialize
    self.connections = {}
  end

  def add(uuid, conn)
    self.connections[uuid] = conn
  end

  def remove(uuid)
    # This preserves `uuid` as a key
    self.connections[uuid] = nil
  end

  def size(with_inactive = false)
    return self.connections.size if with_inactive
    return self.connections.select {|k,v| !v.nil?}.size
  end

  # Remove dead connections
  def purge
    self.connections.keep_if {|k,v| v.nil?}
  end

  # Iterate over active connections
  def each
    self.connections.values.select {|v| !v.nil?}.each do |conn|
      yield conn
    end
  end

  # Iterate over known connections (UUID keys), including those inactive
  def each_uuid
    self.connections.keys.each do |uuid|
      yield uuid
    end
  end

  # Get index of a given connection
  def index(conn)
    return self.connections.values.index(conn)
  end

  def index_uuid(uuid)
    return self.connections.keys.index(uuid)
  end

  #
  # Listeners
  #
  
  def on_connect(conn)
    self.add(conn.uuid, conn)
  end

  def on_disconnect(conn)
    self.remove(conn.uuid)
  end

end
