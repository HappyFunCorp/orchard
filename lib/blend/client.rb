require 'blend/client/hipchat_client'
require 'blend/client/github_client'
require 'blend/client/juice_client'
require 'blend/client/heroku_client'

module Blend
  module Client
    class << self
      def hipchat_client
        @hipchat_client ||= Blend::Client::HipchatClient.new( HipChat::API.new( get_token( :hipchat ) ) )
      end

      def github_client
        @github_client ||= Blend::Client::GithubClient.new( Github.new( oauth_token: get_token( :github ) ) )
      end

      def juice_client( options = {} )
        if( options[:auth_token] )
          if( @juice_client && @juice_client.auth_token != options[:auth_token] )
            @juice_client = nil
            @hipchat_client = nil
            @github_client = nil
          end

          @juice_client ||= Blend::Client::JuiceClient.new options
        end
        
        @juice_client ||= Blend::Client::JuiceClient.new
      end

      def heroku_client
        @heroku_client ||= Blend::Client::HerokuClient.new( Heroku::API.new( api_key: get_token( :heroku ) ) )
      end

      def get_token( type )
        token = case type

        #when :juice
          # Don't use this. This is already handled together with the login
          # stuff in JuiceClient. It could be refactored to fit in with this
          # method a little better, but what'd be the point? It works and
          # it's straightforward.
        when :hipchat
          ENV['HIPCHAT_API_TOKEN'] || juice_client.hipchat_api
        when :github
          ENV['GITHUB_API_TOKEN'] || juice_client.auth( "github" )
        when :heroku
          # Opt for the organization-wide heroku api token:
          ENV['HEROKU_API_TOKEN'] || juice_client.heroku_api
          # Instead of per-user heroku auth:
          #ENV['HEROKU_API_TOKEN'] || juice_client.auth( "heroku" )
        else
          throw "Unknown token type #{type}".red
        end

        
        throw "Token not found for #{type}" if token.nil? || token == ""

        token
      end
    end
  end
end
