class Leiamsync::LocalTransporter
  include Leiamsync::Loggable

  def initialize(path)
    @path = path
  end

  def execute(watcher, path_info)
    d("fired #{path_info.inspect}")
    out_full_path = File.join(@path, path_info.path)
    out_full_tmp_path = File.join(File.dirname(out_full_path),
                                  ".leiamsync_tmp_" +
                                  File.basename(out_full_path))
    case path_info.action
    when :modify
      d("opening #{path_info.path}")
      in_file = watcher.open_file(path_info.path, UV::FS::O_RDONLY,
                                  UV::FS::S_IREAD)
      out_tmp_file = UV::FS.open(out_full_tmp_path,
                                 UV::FS::O_CREAT | UV::FS::O_WRONLY,
                                 path_info.mode)
      d("transferring #{path_info.path} => #{out_full_tmp_path}")
      d("doing sendfile #{path_info.size} bytes")
      UV::FS.sendfile(out_tmp_file, in_file, 0, path_info.size)
      d("done sendfile #{path_info.size} bytes")
      d("closing #{out_full_tmp_path}")
      out_tmp_file.close
      d("closed #{out_full_tmp_path}")
      d("closing #{path_info.path}")
      watcher.close_file(in_file)
      d("closed #{path_info.path}")
      atime = Time.at(*path_info.atime)
      mtime = Time.at(*path_info.mtime)
      d("setting atime and mtime")
      UV::FS.utime(out_full_tmp_path, atime.to_f, mtime.to_f)
      d("set atime and mtime")
      d("renaming #{out_full_tmp_path} => #{out_full_path}")
      UV::FS.rename(out_full_tmp_path, out_full_path)
      d("renamed #{out_full_tmp_path} => #{out_full_path}")
      d("transferred #{path_info.path} => #{out_full_path}")
    when :remove
      if out_full_path.exist?
        UV::FS.rename(out_full_path, out_full_tmp_path)
        if File.directory?(out_full_tmp_path)
          UV::FS.rmdir(out_full_tmp_path)
        else
          UV::FS.unlink(out_full_tmp_path)
        end
        d("done remove #{out_full_path.inspect}")
      else
        d("already not exist #{out_full_path.inspect}")
      end
    else
      raise "unknown action: #{path_info.inspect}"
    end
  end
end
