$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blend/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blend"
  s.version     = Blend::VERSION
  s.authors     = ["Ricky Reusser","Will Schenk"]
  s.email       = ["ricky@happyfuncorp.com","will@happyfuncorp.com"]
  s.homepage    = "http://happyfuncorp.com"
  s.summary     = "Let's make some juice!"
  s.description = "Project management for HappyFunCorp projects."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
  s.test_files = Dir["test/**/*"]
  s.executables << 'blend'

  s.add_dependency "thor"
  s.add_dependency "hipchat-api"
  s.add_dependency "github_api"
  s.add_dependency "httparty"
  s.add_dependency "highline"
  s.add_dependency "colorize"
  s.add_dependency "heroku-api"
  s.add_dependency "heroku"
  s.add_dependency "dnsruby"
  s.add_dependency "whois"
  s.add_dependency "httpclient"
end
