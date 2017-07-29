class Leiamsync::RemoveAction < Leiamsync::Action
  def execute(base_path)
    target_full_path = File.join(base_path, @path)
    if !File.exist?(target_full_path)
      d("already not exist", target: target_full_path)
      return
    end
    target_full_tmp_path = File.join(File.dirname(target_full_path),
                                     ".leiamsync_tmp_" +
                                     File.basename(target_full_path))
    UV::FS.rename(target_full_path, target_full_tmp_path)
    if File.directory?(target_full_tmp_path)
      UV::FS.rmdir(target_full_tmp_path)
    else
      UV::FS.unlink(target_full_tmp_path)
    end
    d("done remove", target: target_full_path)
  end
end
