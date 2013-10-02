require 'highline/import'

module Orchard
  module Client
    class JuiceClient
      include HTTParty

      class << self
        
        # Wrap HHTParty's get method so we can actually catch errors
        def get( url, *args )
          response = super( url, *args )
          case response.code
            when 401
              raise Exceptions::AuthenticationFailure
          end
          return response
        end

        def post( url, *args )
          response = super( url, *args )
          case response.code
            when 401
              raise Exceptions::AuthenticationFailure
          end
          return response
        end


      end

      base_uri ENV['JUICE_API_ENDPOINT'] || 'http://happyfunjuice.com/api'
      # debug_output $stderr
      
      def login
        query_login
      end

      def logout
        destroy_auth_token
      end

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

      def activities( project_id, after, before = Time.now )
        auth_token
        activities = self.class.get "/projects/#{project_id}/activities.json", {query: { after: after.to_i, before: before.to_i } }
        activities_stats activities, after, before
      end

      def activities_stats( activities, after, before )
        stats = { type: {}, 
                  actors_activites: {}, 
                  activities: activities, 
                  after: after, 
                  before: before, 
                  active_tickets: {},
                  closed_tickets: {}}

        activities.each do |x|
          x['happened_at'] = Time.parse x['happened_at']
        end.sort do |a,b|
          a['happened_at'] <=> b['happened_at']
        end.each do |a|
          actor = a['actor_identifier']
          type = a['activity_type']
          stats[:type][type] ||= []
          stats[:type][type] << a

          if( !(type =~ /^juice/) && !(type =~ /tweet/) )
            stats[:actors_activites][type] ||= {}
            stats[:actors_activites][type][actor] ||= []
            stats[:actors_activites][type][actor] << a
          end
        end

        stats
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

      def config_file
        "#{ENV['HOME']}/.juice.yml"
      end

      def destroy_auth_token
        _prev_options = @options
        begin
          return File.delete config_file
        rescue Errno::ENOENT
          raise Exceptions::AlreadyLoggedOut
        ensure
          @options = {}
        end
        _prev_options
      end

      
      def query_login

        begin
          response = read_auth_token
          @options = response

          # If it doesn't contain an auth_token, it's as good as not existing:

          raise Exceptions::AlreadyLoggedIn

        rescue Errno::ENOENT
          username = ask( "Username : " ) { |q| q.echo = true }
          password = ask( "Password : " ) { |q| q.echo = '.' }

          response = self.class.post "/auth", {body: { username: username, password: password } }

          raise Exceptions::LoginAuthenticationFailure if response['auth_token'].blank?

          @options = response.parsed_response

          write_auth_token( @options )
        end
      end


      def read_auth_token
        begin
          response = YAML.load( File.read( config_file ) )
          raise StandardError.new unless response['auth_token']
          response
        rescue StandardError
          raise Errno::ENOENT
        end
      end


      def write_auth_token( options )
        File.open( config_file, "w" ) do |o|
          o.puts YAML.dump( options || {} )
        end
        return options
      end


      def auth_token
        begin
          query_login
        rescue Exceptions::AlreadyLoggedIn
        end
        self.class.default_params auth_token: @options['auth_token']
        @options['auth_token']
      end

    end
  end
end
