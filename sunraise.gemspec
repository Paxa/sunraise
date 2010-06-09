Gem::Specification.new do |s|
  s.name              = "sunraise"
  s.version           = "0.1.4"
  s.summary           = "Super-fast and simple rails deployment."
  s.description       = "Super-fast and simple rails deployment"
  s.author            = "Pavel Evstigneev"
  s.email             = "pavel.evst@gmail.com"
  s.homepage          = "http://github.com/Paxa/sunraise"
  s.has_rdoc          = false
  s.executables       = ["sunraise"]
  s.rubyforge_project = "sunraise"
  s.files             = [ "bin/sunraise", "lib/config.rb", "lib/deployer.rb", 
    "lib/generator.rb", "README.md", "sunraise.gemspec", 'sunraise-template.erb', 'lib/generator.rb']

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rainbow>, [">= 1.0.4"])
      s.add_runtime_dependency(%q<net-ssh>, [">= 2.0.23"])
      
    else
      s.add_dependency(%q<rainbow>, [">= 1.0.4"])
      s.add_dependency(%q<net-ssh>, [">= 2.0.23"])
    end
  else
    s.add_dependency(%q<rainbow>, [">= 1.0.4"])
    s.add_dependency(%q<net-ssh>, [">= 2.0.23"])
  end
end
