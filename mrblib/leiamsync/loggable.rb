module Leiamsync::Loggable
  class << self
    attr_accessor :logger
  end

  def d(message)
    Leiamsync::Loggable.logger.debug(message)
  end
end
