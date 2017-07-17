module Liamsync
end

def __main__(argv)
  $l = Logger.new(STDOUT)
  Liamsync::Cli.new(argv).run
end
