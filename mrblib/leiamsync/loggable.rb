module Leiamsync::Loggable
  class << self
    attr_accessor :logger

    def format_message(message, extra = nil)
      # Kernel#caller_locations is not defined in mruby-1.3.0.
      a = caller(2, 1)
      filename_and_line_number = a.first[/[\w.]+:\d+/]
      extra_s = ""
      if extra
        extra_s = ": " + extra.map { |k, v|
          "#{k}=#{v.inspect}"
        }.join(" ")
      end
      return filename_and_line_number + ":" + message + extra_s
    end
  end

  private

  def d(*args)
    Leiamsync::Loggable.logger.debug(Leiamsync::Loggable.format_message(*args))
  end

  def w(*args)
    Leiamsync::Loggable.logger.warn(Leiamsync::Loggable.format_message(*args))
  end
end
