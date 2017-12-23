class Leiamsync::LocalWatcher
  include Leiamsync::Loggable

  def initialize(path)
    @events = []
    @path = path
  end

  def start(&block)
    d("starting #{@path.inspect}")
    start_recursive(".", &block)
    d("started #{@path.inspect}")
  end

  def stop
    d("stopping #{@path.inspect}")
    @events.reverse_each(&:stop)
    d("stopped #{@path.inspect}")
  end

  private

  # from stat(2)
  S_IFMT = 0170000
  S_IFREG = 0100000
  S_IFDIR = 0040000

  def start_recursive(relative_path, &block)
    path = File.join(@path, relative_path)
    # UV::FS::Event::RECURSIVE is no effect on Linux.
    # http://docs.libuv.org/en/v1.x/fs_event.html#c.uv_fs_event_start
    event = UV::FS::Event.new
    @events << event
    event.start(path, 0) do |changed_filename, event_type|
      changed_path =
        File.join(relative_path, changed_filename).sub(%r|\A./|, "")
      d("fired #{event_type.inspect} #{changed_path.inspect}")
      action = create_action(changed_path, event_type)
      if !action
        next
      end
      d("created", action: action)
      block.call(action)
    end
    UV::FS.readdir(path, 0).sort.each do |filename, type|
      if :dir == type
        start_recursive(File.join(relative_path, filename), &block)
      end
    end
  end

  def create_action(path, event_type)
    full_path = File.expand_path(path, @path)
    if %r/(?:\A|\/)\.leiamsync_tmp_/ =~ full_path
      d("skip #{event_type.inspect} #{path.inspect}")
      return nil
    end
    if !File.exist?(full_path)
      return Leiamsync::RemoveAction.new(path)
    end
    stat = UV::FS.stat(full_path)
    if stat.mode & S_IFREG > 0
      type = :file
      f = UV::FS.open(full_path, UV::FS::O_RDONLY, UV::FS::S_IREAD)
      begin
        content = f.read
      ensure
        f.close
      end
    elsif stat.mode & S_IFDIR > 0
      type = :directory
      content = nil
    else
      raise "unknown file type: #{'%06o' % stat.mode} #{full_path.inspect}"
    end
    # TODO: new directory: sub_watchers?
    return Leiamsync::ModifyAction.new(path, type,
                                       stat.mode & S_IFMT ^ stat.mode,
                                       stat.atim, stat.mtim, content)
  end
end
