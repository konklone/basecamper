require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'time-tracker'
  s.version = "1.0.0"
  s.platform = Gem::Platform::RUBY
  s.summary = "A command line time tracker interface for time logging in Basecamp."
  
  s.author = "Eric Mill"
  s.email = "kprojection@gmail.com"
  # s.homepage = 


  s.files = Dir.glob("{bin,lib,data}/**/*") + %w(README LICENSE)
  s.require_path = 'lib'
  s.autorequire = 'time_tracker'
  
  s.bindir = "bin"
  s.executables << "track"
  
  s.add_dependency 'xml-simple'
end

if $0==__FILE__
  require 'rubygems/builder'
  Gem::Builder.new(spec).build
end
