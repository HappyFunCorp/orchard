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

      def auth_token
        unless @auth_token
          file = "#{ENV['HOME']}/.juicerc"
          if File.exists? file
            @auth_token = File.read( file ).gsub( /\s/m, "" )
          else
            puts "#{file} not found, logging into happyfunjuice.com"
            username = ask( "Username : " ) { |q| q.echo = true }
            password = ask( "Password : " ) { |q| q.echo = '.' }

            resp = self.class.post "/auth", {body: { username: username, password: password } }
            pp resp
            if resp['auth_token']
              @auth_token = resp['auth_token']
              File.open( file, "w" ) do |o|
                o.puts @auth_token
              end
            end
          end
          self.class.default_params auth_token: @auth_token
        end

        @auth_token
      end
    end
  end
end