class Time
  alias tv_sec to_i
  alias tv_usec usec

  def to_f
    return tv_sec + tv_usec / 1_000_000.0
  end
end
