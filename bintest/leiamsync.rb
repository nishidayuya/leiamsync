require "pathname"
require "timeout"
require "time"

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/leiamsync")
VERY_LONG_TIME_SEC = 5

class Time
  def inspect
    return iso8601(6)
  end
end

class BackgroundRunner
  def self.run(*args, &block)
    result = new(*args)
    result.run(&block)
    return result
  end

  def initialize(*args)
    @args = args
  end

  def run
    @pid = spawn(*@args)
    @thread = Process.detach(@pid)
    if block_given?
      yield
    end
  ensure
    if block_given?
      kill
      wait
    end
  end

  def kill(signal = :SIGTERM)
    Process.kill(signal, @pid)
  end

  def wait
    @process_status = @thread.value
  end
end

def assert_leiamsync(case_name, &block)
  assert(case_name) do
    Dir.mktmpdir do |d|
      tmp_path = Pathname(d).expand_path
      root1 = tmp_path / "1"
      root2 = tmp_path / "2"
      root1.mkpath
      root2.mkpath
      BackgroundRunner.run(BIN_PATH, root1.to_s, root2.to_s) do
        sleep(0.1) # TODO: wait for wakeup
        block.call(root1, root2)
      end
    end
  end
end

def assert_retried
  assert_nothing_raised do
    Timeout.timeout(VERY_LONG_TIME_SEC) do
      while !yield
        sleep(0.1)
      end
    end
  end
end

def assert_path_stat(expected_path, actual_path)
  expected_stat = expected_path.stat
  actual_stat = actual_path.stat

  [:mode, :uid, :gid].each do |a|
    assert_equal(expected_stat.send(a), actual_stat.send(a))
  end

  # currently accuracy of transferred times are seconds.
  # ignore micro seconds.
  [:atime, :mtime].each do |a|
    assert_equal(Time.at(expected_stat.send(a).tv_sec),
                 Time.at(actual_stat.send(a).tv_sec))
  end
end

assert_leiamsync("sync local files") do |root1, root2|
  # new file
  path1 = root1 / "file1.txt"
  path2 = root2 / "file1.txt"
  path1.write("This is new file.")
  assert_retried {
    path2.exist? && "This is new file." == path2.read
  }
  assert_path_stat(path1, path2)

  # append exist file
  path1.open("a") do |f|
    f.puts
    f.puts("This is appended line.")
  end
  assert_retried {
    "This is new file.\nThis is appended line.\n" == path2.read
  }
  assert_path_stat(path1, path2)

  # write whole file
  path1.write("Wrote whole file.\n")
  assert_retried {
    "Wrote whole file.\n" == path2.read
  }
  assert_path_stat(path1, path2)

  # delete file
  path1.delete
  assert_retried {
    !path2.exist?
  }
end
