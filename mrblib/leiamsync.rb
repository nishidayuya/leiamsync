module Leiamsync
end

def __main__(argv)
  $l = Logger.new(STDOUT)
  Leiamsync::Cli.new(argv).run
end
