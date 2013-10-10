require 'thor'
require 'colorize'
require 'hipchat-api'
require 'github_api' # Note the underbar
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric'
require 'orchard/core_ext/string'
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
