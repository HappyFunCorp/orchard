require 'thor'
require 'colorize'
require 'hipchat-api'
require 'github_api' # Note the underbar
require 'heroku-api'

require 'blend/core_ext/string'
require 'blend/core_ext/object'
require 'blend/core_ext/fixnum'

# require 'blend/domain_checker'
require 'blend/exceptions'
require 'blend/cli'
require 'blend/client'
require 'blend/status/project'
require 'blend/version'

require 'pp'

begin
  Lita
  require 'blend/chatbot/bot'
rescue NameError
end

module Blend

end
