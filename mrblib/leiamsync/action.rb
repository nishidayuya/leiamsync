class Leiamsync::Action
  include Leiamsync::Loggable

  def initialize(path)
    @path = path
  end
end
