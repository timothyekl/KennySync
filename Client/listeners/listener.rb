module Listener
  def listener?
    return true
  end

  # The rest of these methods are just no-op placeholders.
  # They serve as a full list of what methods are available
  # for override by classes mixing in the Listener module.

  def on_connect(conn) end
  def on_receive(message) end
  def on_send(message) end
  def on_state_change(description, conn) end
  def on_disconnect(conn) end
  def on_log(message, level) end
end
