require 'orchard/client/hipchat_client'
require 'orchard/client/github_client'
require 'orchard/client/juice_client'
require 'orchard/client/heroku_client'

module Orchard
  module Client
    class << self
      def hipchat_client
        @hipchat_client ||= Orchard::Client::HipchatClient.new( HipChat::API.new( get_token( :hipchat ) ) )
      end

      def github_client
        @github_client ||= Orchard::Client::GithubClient.new( Github.new( oauth_token: get_token( :github ) ) )
      end

      def juice_client
        @juice_client ||= Orchard::Client::JuiceClient.new
      end

      def heroku_client
        @heroku_client ||= Orchard::Client::HerokuClient.new( Heroku::API.new( api_key: get_token( :heroku ) ) )
      end

      def get_token( type )
        #print "Looking for #{type} token: "
        #$stderr.flush
        token = case type
        when :hipchat
          ENV['HIPCHAT_API_TOKEN'] || juice_client.hipchat_api
        when :github
          ENV['GITHUB_API_TOKEN'] || juice_client.auth( "github" )
        when :heroku
          # Opt for the organization-wide heroku api token:
          ENV['HEROKU_API_TOKEN'] || juice_client.heroku_api
          #ENV['HEROKU_API_TOKEN'] || juice_client.auth( "heroku" )
        else
          throw "Unknown token type #{type}".red
        end

        
        throw "Token not found for #{type}" if token.nil? || token == ""

        #$stderr.puts "#{token}"
        token
      end
    end
  end
end
