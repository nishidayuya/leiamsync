class Leiamsync::LocalTransporter
  include Leiamsync::Loggable

  def initialize(path)
    @path = path
  end

  def start(watcher)
    watcher.start do |path_info|
      d("LocalTransporter: fired #{path_info.inspect}")
      out_full_path = File.join(@path, path_info.path)
      out_full_tmp_path = File.join(File.dirname(out_full_path),
                                    ".leiamsync_tmp_" +
                                    File.basename(out_full_path))
      case path_info.action
      when :modify
        d("LocalTransporter: opening #{path_info.path}")
        in_file = watcher.open_file(path_info.path, UV::FS::O_RDONLY,
                                    UV::FS::S_IREAD)
        out_tmp_file = UV::FS.open(out_full_tmp_path,
                                   UV::FS::O_CREAT | UV::FS::O_WRONLY,
                                   path_info.mode)
        d("LocalTransporter: transferring #{path_info.path} => #{out_full_tmp_path}")
        d("LocalTransporter: doing sendfile #{path_info.size} bytes")
        UV::FS.sendfile(out_tmp_file, in_file, 0, path_info.size)
        d("LocalTransporter: done sendfile #{path_info.size} bytes")
        d("LocalTransporter: closing #{out_full_tmp_path}")
        out_tmp_file.close
        d("LocalTransporter: closed #{out_full_tmp_path}")
        d("LocalTransporter: closing #{path_info.path}")
        watcher.close_file(in_file)
        d("LocalTransporter: closed #{path_info.path}")
        atime = Time.at(*path_info.atime)
        mtime = Time.at(*path_info.mtime)
        d("LocalTransporter: setting atime and mtime")
        UV::FS.utime(out_full_tmp_path, atime.to_f, mtime.to_f)
        d("LocalTransporter: set atime and mtime")
        d("LocalTransporter: renaming #{out_full_tmp_path} => #{out_full_path}")
        UV::FS.rename(out_full_tmp_path, out_full_path)
        d("LocalTransporter: renamed #{out_full_tmp_path} => #{out_full_path}")
        d("LocalTransporter: transferred #{path_info.path} => #{out_full_path}")
      when :remove
        if out_full_path.exist?
          UV::FS.rename(out_full_path, out_full_tmp_path)
          if File.directory?(out_full_tmp_path)
            UV::FS.rmdir(out_full_tmp_path)
          else
            UV::FS.unlink(out_full_tmp_path)
          end
          d("LocalTransporter: done remove #{out_full_path.inspect}")
        else
          d("LocalTransporter: already not exist #{out_full_path.inspect}")
        end
      else
        raise "unknown action: #{path_info.inspect}"
      end
    end
  end

  def stop
  end

  def apply(file_info)
  end

  private

  def prepare
  end

  def read
  end

  def write
  end
end
