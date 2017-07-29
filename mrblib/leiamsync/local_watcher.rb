class Leiamsync::LocalWatcher
  include Leiamsync::Loggable

  def initialize(path)
    @event = UV::FS::Event.new
    @path = path
  end

  def start(&block)
    d("starting #{@path.inspect}")
    @event.start(@path, UV::FS::Event::RECURSIVE) do |path, event_type|
      d("fired #{event_type.inspect} #{path.inspect}")
      full_path = File.expand_path(path, @path)
      if %r/(?:\A|\/)\.leiamsync_tmp_/ =~ full_path
        d("skip #{event_type.inspect} #{path.inspect}")
      end
      if File.exist?(full_path)
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
        action = Leiamsync::ModifyAction.new(path, type,
                                             stat.mode & S_IFMT ^ stat.mode,
                                             stat.atim, stat.mtim, content)
      else
        action = Leiamsync::RemoveAction.new(path)
      end
      d("created", action: action)
      block.call(action)
    end
    d("started #{@path.inspect}")
  end

  def stop
    d("stopping #{@path.inspect}")
    @event.stop
    d("stopped #{@path.inspect}")
  end

  private

  # from stat(2)
  S_IFMT = 0170000
  S_IFREG = 0100000
  S_IFDIR = 0040000
end
