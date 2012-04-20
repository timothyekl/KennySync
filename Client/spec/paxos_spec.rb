def launch_node(n)
  pids = {}
  1.upto(n).each do |i|
    r, w = IO.pipe
    pid = Process.spawn("ruby run.rb", :chdir => File.join(File.dirname(__FILE__), ".."), :in => r, :out => w)
    sleep 0.1
    pids[pid] = [r, w]
  end
  return pids
end

def killall(pids, signal = "KILL")
  pids.each do |pid, pipe|
    pipe[1].close
    Process.kill(signal, pid)
    Process.waitpid(pid)
  end
end

describe "kennysync" do

  after do
    killall(@pids)
  end

  describe "one-node tests" do

    before do
      @pids = launch_node(1)
    end

    it "should launch a node" do
      @pids.length.should == 1
      @pids.each_key{|pid| pid.should_not == 0}
    end

  end

  describe "two-node tests" do

    before do
      @pids = launch_node(2)
    end

    it "should launch two nodes" do
      @pids.length.should == 2
      @pids.each_key{|pid| pid.should_not == 0}
    end

    it "should establish a connection between the nodes" do
      @pids.each do |pid, pipe|
        puts "Reading..."
        input = pipe[0].readpartial(128)
        puts input
        /connect/.match(input).should_not == nil
      end
    end

  end

end
