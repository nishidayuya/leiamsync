module Leiamsync::Loggable
  class << self
    attr_accessor :logger
  end

  def d(message)
    # Kernel#caller_locations is not defined in mruby-1.3.0.
    a = caller(2, 1)
    filename_and_line_number = a.first[/[\w.]+:\d+/]
    Leiamsync::Loggable.logger.debug(filename_and_line_number + ":" + message)
  end
end
