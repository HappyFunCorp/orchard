$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "orchard/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "orchard"
  s.version     = Orchard::VERSION
  s.authors     = ["Ricky Reusser","Will Schenk"]
  s.email       = ["ricky@happyfuncorp.com","will@happyfuncorp.com"]
  s.homepage    = "http://happyfuncorp.com"
  s.summary     = "Let's make some juice!"
  s.description = "Project management for HappyFunCorp projects."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
  s.test_files = Dir["test/**/*"]
  s.executables << 'orchard'

  #s.add_dependency "rails", "~> 3.2.12"
  
  #s.add_dependency 'haml'
end
