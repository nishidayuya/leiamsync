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
        type = stat.mode & S_IFREG > 0 ? :file :
                 stat.mode & S_IFDIR > 0 ? :directory :
                   nil
        if !type
          raise "unknown file type: #{'%06o' % stat.mode} #{full_path.inspect}"
        end
        # TODO: new directory: sub_watchers?
        path_info = {
          action: :modify,
          path: path,
          type: type,
          mode: stat.mode & S_IFMT ^ stat.mode,
          size: stat.size,
          atime: [stat.atim.tv_sec, stat.atim.tv_usec],
          mtime: [stat.mtim.tv_sec, stat.mtim.tv_usec],
        }
      else
        path_info = {
          action: :remove,
          path: path,
        }
      end
      d("path_info: #{path_info.inspect}")
      block.call(OpenStruct.new(path_info))
    end
    d("started #{@path.inspect}")
  end

  def stop
    d("stopping #{@path.inspect}")
    @event.stop
    d("stopped #{@path.inspect}")
  end

  def open_file(path, flags, mode)
    full_path = File.expand_path(path, @path)
    d("opening #{full_path.inspect}")
    return UV::FS.open(full_path, flags, mode)
  end

  def close_file(file)
    file.close
  end

  private

  # from stat(2)
  S_IFMT = 0170000
  S_IFREG = 0100000
  S_IFDIR = 0040000
end
