# Class that manages connections between Paxos nodes
# Should be available as a singleton in the global $connector

class Connector

  include Enumerable

  def initialize
    @uuids = []
    @connections = {}
  end

  def add(uuid, conn)
    @uuids << uuid
    @connections[uuid] = conn
  end

  def remove(uuid)
    # This preserves `uuid` as a key
    @connections[uuid] = nil
  end

  # Check whether the given connection is known (active or inactive)
  def include?(conn)
    return @uuids.include? conn.uuid
  end

  # Check whether a connection to the given host is known (active or inactive)
  def include_conn_to?(ip, port)
    self.each do |conn|
      return true if conn.ip == ip and conn.port == port
    end
    return false
  end

  # Check whether the given UUID is known (active or inactive)
  def include_uuid?(uuid)
    return @uuids.include? uuid
  end

  def size(with_inactive = false)
    return @uuids.size if with_inactive
    return @connections.select {|k,v| !v.nil?}.size
  end

  # Remove dead connections
  def purge
    raise "Unimplemented"
  end

  # Iterate over active connections
  def each
    @uuids.each do |uuid|
      if !@connections[uuid].nil?
        yield @connections[uuid]
      end
    end
  end

  # Iterate over all connections
  def each_with_inactive
    @uuids.each do |uuid|
      yield @connections[uuid]
    end
  end

  # Iterate over known active connections (UUID keys)
  def each_uuid
    @uuids.select {|u| !@connections[u].nil?}.each do |uuid|
      yield uuid
    end
  end

  # Iterate over all known connections, including those inactive
  def each_uuid_with_inactive
    @uuids.each do |uuid|
      yield uuid
    end
  end

  # Get index of a given connection
  def index(conn)
    return @uuids.select {|u| !@connections[u].nil?}.index(conn.uuid)
  end

  def index_uuid(uuid)
    return @uuids.select {|u| !@connections[u].nil?}.index(uuid)
  end
end
