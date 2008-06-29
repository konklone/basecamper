require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'basecamper'
  s.version = "1.0.1"
  s.platform = Gem::Platform::RUBY
  s.summary = "Command line interface to tracking time on Basecamp."
  
  s.author = "Eric Mill"
  s.email = "kprojection@gmail.com"
  s.homepage = "http://github.com/Klondike/basecamper/"


  s.files = Dir.glob("{bin,lib}/**/*") + %w(README LICENSE)
  s.require_path = 'lib'
  s.autorequire = 'basecamper'
  
  s.bindir = "bin"
  s.executables << "track"
  
  s.add_dependency 'xml-simple'
end

if $0==__FILE__
  require 'rubygems/builder'
  Gem::Builder.new(spec).build
end
