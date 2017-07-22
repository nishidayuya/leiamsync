module Leiamsync
end

def __main__(argv)
  Leiamsync::Loggable.logger = Logger.new(STDOUT)
  Leiamsync::Cli.new(argv).run
end
