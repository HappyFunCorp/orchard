require 'thor'
require 'colorize'
require 'hipchat-api'
require 'github_api' # Note the underbar
require 'heroku-api'

require 'orchard/core_ext/string'
require 'orchard/core_ext/object'
require 'orchard/core_ext/fixnum'

require 'orchard/domain_checker'
require 'orchard/exceptions'
require 'orchard/cli'
require 'orchard/client'
require 'orchard/status/status'
require 'orchard/version'

require 'pp'

begin
  Lita
  require 'orchard/chatbot/bot'
rescue NameError
end

module Orchard

end
