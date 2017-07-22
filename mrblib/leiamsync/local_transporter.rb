class Leiamsync::LocalTransporter
  def initialize(path)
    @path = path
  end

  def start(watcher)
    watcher.start do |path_info|
      $l.debug("LocalTransporter: fired #{path_info.inspect}")
      out_full_path = File.join(@path, path_info.path)
      out_full_tmp_path = File.join(File.dirname(out_full_path),
                                    ".leiamsync_tmp_" +
                                    File.basename(out_full_path))
      case path_info.action
      when :modify
        $l.debug("LocalTransporter: opening #{path_info.path}")
        in_file = watcher.open_file(path_info.path, UV::FS::O_RDONLY,
                                    UV::FS::S_IREAD)
        out_tmp_file = UV::FS.open(out_full_tmp_path,
                                   UV::FS::O_CREAT | UV::FS::O_WRONLY,
                                   path_info.mode)
        $l.debug("LocalTransporter: transferring #{path_info.path} => #{out_full_tmp_path}")
        $l.debug("LocalTransporter: doing sendfile #{path_info.size} bytes")
        UV::FS.sendfile(out_tmp_file, in_file, 0, path_info.size)
        $l.debug("LocalTransporter: done sendfile #{path_info.size} bytes")
        $l.debug("LocalTransporter: closing #{out_full_tmp_path}")
        out_tmp_file.close
        $l.debug("LocalTransporter: closed #{out_full_tmp_path}")
        $l.debug("LocalTransporter: closing #{path_info.path}")
        watcher.close_file(in_file)
        $l.debug("LocalTransporter: closed #{path_info.path}")
        atime = Time.at(*path_info.atime)
        mtime = Time.at(*path_info.mtime)
        $l.debug("LocalTransporter: setting atime and mtime")
        UV::FS.utime(out_full_tmp_path, atime.to_f, mtime.to_f)
        $l.debug("LocalTransporter: set atime and mtime")
        $l.debug("LocalTransporter: renaming #{out_full_tmp_path} => #{out_full_path}")
        UV::FS.rename(out_full_tmp_path, out_full_path)
        $l.debug("LocalTransporter: renamed #{out_full_tmp_path} => #{out_full_path}")
        $l.debug("LocalTransporter: transferred #{path_info.path} => #{out_full_path}")
      when :remove
        if out_full_path.exist?
          UV::FS.rename(out_full_path, out_full_tmp_path)
          if File.directory?(out_full_tmp_path)
            UV::FS.rmdir(out_full_tmp_path)
          else
            UV::FS.unlink(out_full_tmp_path)
          end
          $l.debug("LocalTransporter: done remove #{out_full_path.inspect}")
        else
          $l.debug("LocalTransporter: already not exist #{out_full_path.inspect}")
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
