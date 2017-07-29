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
    transporter = LocalTransporter.new(to)
    watcher = LocalWatcher.new(from)
    watcher.start do |action|
      transporter.execute(action)
    end

    d("start UV loop")
    UV.run
  end
end
