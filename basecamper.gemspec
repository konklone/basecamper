spec = Gem::Specification.new do |s|
  s.name = 'basecamper'
  s.version = "1.0.2"
  s.platform = Gem::Platform::RUBY
  s.summary = "Command line interface to tracking time on Basecamp."
  
  s.author = "Eric Mill"
  s.email = "kprojection@gmail.com"
  s.homepage = "http://github.com/Klondike/basecamper/"

  s.files = ['README' 'LICENSE', 'bin/track', 'lib/basecamp.rb', 'lib/basecamper.rb']
  s.require_path = 'lib'
  
  s.bindir = "bin"
  s.executables << "track"
  
  s.add_dependency 'xml-simple'
end
