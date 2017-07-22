module Leiamsync
  # If remove this empty definition, mruby-1.3.0 raises NameError.
end

module Leiamsync::Loggable
  # If remove this empty definition, mruby-1.3.0 raises NameError.
end

class Leiamsync::Cli
  include Leiamsync::Loggable

  def initialize(argv)
    @argv = argv
  end

  def run
    from = @argv[1]
    to = @argv[2]
    if !to
      STDERR.puts("USAGE: leiamsync from_path to_path")
      exit(1)
    end
    watcher = LocalWatcher.new(from)
    transporter = LocalTransporter.new(to)
    transporter.start(watcher)
    d("Cli: start UV loop")
    UV.run
  end
end
