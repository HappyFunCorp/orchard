require 'highline/import'

module Orchard
  module Client
    class JuiceClient
      include HTTParty
      base_uri 'http://happyfunjuice.com/api'

      def projects
        auth_token
        self.class.get "/projects.json"
      end

      def auths
        auth_token
        @auths ||= self.class.get "/profile/authentications.json"
      end

      def auth( provider )
        auths.select do |x|
          return x['token'] if x['provider'] == provider
        end

        nil
      end

      def hipchat_api( token = nil )
        auth_token
        ret = {}
        if( token )
          ret = self.class.post "/organizations/1/hipchat/auth_token.json", {query: {hipchat_auth_token: token}}
        else
          ret = self.class.get "/organizations/1/hipchat/auth_token.json"
        end
        ret['hipchat_auth_token']
      end

      def auth_token
        file = "#{ENV['HOME']}/.juice.yml"

        unless @options
          if File.exists? file
            @options = YAML.load( File.read( file ) )
          end
        end

        @options ||= {}

        if !@options['auth_token']
          puts "#{file} not found, logging into happyfunjuice.com"
          username = ask( "Username : " ) { |q| q.echo = true }
          password = ask( "Password : " ) { |q| q.echo = '.' }

          resp = self.class.post "/auth", {body: { username: username, password: password } }
          pp resp
          if resp['auth_token']
            @options['auth_token'] = resp['auth_token']
          end
        end

        self.class.default_params auth_token: @options['auth_token'] if @options['auth_token']

  
        File.open( file, "w" ) do |o|
          o.puts YAML.dump( @options || {} )
        end

        @options['auth_token']
      end
    end
  end
end