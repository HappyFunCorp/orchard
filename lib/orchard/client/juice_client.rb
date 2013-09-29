require 'highline/import'

module Orchard
  module Client
    class JuiceClient
      include HTTParty
      base_uri ENV['JUICE_API_ENDPOINT'] || 'http://happyfunjuice.com/api'
      # debug_output $stderr

      def create_project( name )
        auth_token
        pp self.class.post "/organizations/1/projects", { query: { "project[name]" => name } }
        @projects = nil
      end

      def projects
        auth_token
        @projects ||= self.class.get( "/projects.json" ).each do |x|
          x['orchard_config'] ||= {}
          x['orchard_config']['teams'] ||= []
        end
      end

      def project_id_from_name( name )
        return name if name =~ /^[0-9]+$/

        projects.each do |project|
          return project['id'] if project['name'] == name
        end

        puts "Couldn't find project #{name}"
        nil
      end

      def project( id )
        auth_token
        data = self.class.get "/projects/#{id}.json"

        data['orchard_config'] ||= {}
        data['orchard_config']['teams'] ||= []

        data
      end

      def project_users( id )
        auth_token
        self.class.get "/projects/#{id}/users.json"
      end

      def project_config( id, config = nil )
        auth_token
        if( config.nil? )
          puts "Loading config"
          project = self.class.get "/projects/#{id}.json"
          project['orchard_config'] || {}
        else
          puts "Setting config #{config}"
          self.class.put "/projects/#{id}.json", { query: { project: { orchard_config: config } } }
          @projects = nil
        end
      end

      def project_add_team( id, github_team )
        config = project_config( id )
        config['teams'] ||= []
        config['teams'] << github_team
        project_config( id, config )
      end

      def project_add_hipchat( id, hipchat )
        config = project_config( id )
        config['hipchat_room'] = hipchat
        project_config( id, config )
      end

      def feeds( id )
        auth_token
        self.class.get "/projects/#{id}/feeds.json"
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

      def hipchat_check
        hipchat_client = Orchard::Client.hipchat_client

        rooms = {}
        hipchat_client.rooms.each { |x| rooms[x['name']] = [] }

        projects.each do |project|
          room = project['orchard_config']['hipchat_room']
          if room
            rooms[room] ||= []
            rooms[room] << project['name']
          end
        end

        rooms.keys.sort { |a,b| a <=> b }.collect do |room|
          if rooms[room].size == 0
            rooms[room] << "_unassigned_"
          end
          { room: room, projects: rooms[room] }
        end
      end

      def auth_token
        file = "#{ENV['HOME']}/.juice.yml"

        unless @options
          if File.exists? file
            @options = YAML.load( File.read( file ) )
            puts "Juice: #{@options['auth_token']}"
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