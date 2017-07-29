class Leiamsync::ModifyAction < Leiamsync::Action
  def initialize(path, type, mode, atime, mtime, content)
    super(path)
    @type = type
    @mode = mode
    @atime = atime
    @mtime = mtime
    @content = content
  end

  def execute(base_path)
    target_full_path = File.join(base_path, @path)
    target_full_tmp_path = File.join(File.dirname(target_full_path),
                                     ".leiamsync_tmp_" +
                                     File.basename(target_full_path))

    d("writing", tmp_path: target_full_tmp_path)
    write_content_to(target_full_tmp_path)
    d("renaming #{target_full_tmp_path} => #{target_full_path}")
    UV::FS.rename(target_full_tmp_path, target_full_path)
    d("renamed #{target_full_tmp_path} => #{target_full_path}")
    d("done", path: @path)
  end

  private

  def write_content_to(path)
    target_tmp_file = UV::FS.open(path,
                                  UV::FS::O_CREAT | UV::FS::O_WRONLY,
                                  @mode)
    begin
      target_tmp_file.write(@content)
    ensure
      target_tmp_file.close
    end
    UV::FS.utime(path, @atime.to_f, @mtime.to_f)
  end
end
