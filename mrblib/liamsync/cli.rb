module Liamsync
end

class Liamsync::Cli
  def initialize(argv)
    @argv = argv
  end

  def run
    from = @argv[1]
    to = @argv[2]
    if !to
      STDERR.puts("USAGE: liamsync from_path to_path")
      exit(1)
    end
    watcher = LocalWatcher.new(from)
    transporter = LocalTransporter.new(to)
    transporter.start(watcher)
    $l.debug("Cli: start UV loop")
    UV.run
  end
end
