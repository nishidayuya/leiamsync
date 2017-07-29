class Leiamsync::LocalTransporter
  include Leiamsync::Loggable

  def initialize(path)
    @path = path
  end

  def execute(action)
    action.execute(@path)
  end
end
