require 'thor'
require 'colorize'
require 'hipchat-api'
require 'github_api' # Note the underbar
require 'orchard/exceptions'
require 'orchard/cli'
require 'orchard/client'
require 'orchard/version'

require 'pp'

begin
  Lita
  require 'orchard/bot'
rescue NameError
end

module Orchard

end
