MRuby::Gem::Specification.new('liamsync') do |spec|
  spec.license = "X11"
  spec.author = "Yuya.Nishida."
  spec.summary = "semi-realtime directory synchronization tool"
  spec.bins = ["liamsync"]

  spec.add_dependency("mruby-exit", core: "mruby-exit")
  spec.add_dependency("mruby-mtest", mgem: "mruby-mtest")
  spec.add_dependency("mruby-io")
  spec.add_dependency("mruby-onig-regexp")
  spec.add_dependency("mruby-logger")
  spec.add_dependency("mruby-uv")
  spec.add_dependency("mruby-ostruct")
end
