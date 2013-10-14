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

      def summary
        auth_token
        @projects ||= self.class.get( "/projects/summary.json" ).each do |x|
          x['orchard_config'] ||= {}
          x['orchard_config']['teams'] ||= []
        end
      end

      def organizations
        auth_token
        @organizations ||= self.class.get( "/organizations.json" ).each do |o|
          o['orchard_config'] ||= {}
        end
      end

      def project_info_from_room( room )
        auth_token
        if room =~ /[0-9]+_[^@]+@.*/
          room_name = Orchard::Client.hipchat_client.room_name_from_xmpp_jid( room )
        else
          room_name = room
        end
        return nil if room_name.nil? or room_name.length==0
        projects.select{|x| (x['orchard_config']['hipchat_room'].downcase rescue nil) == room_name.downcase}.first
      end

      def project_id_from_room( room )
        @project_ids_from_rooms ||= {}
        p = project_info_from_room( room )
        if p.nil?
          nil
        else
          @project_ids_from_rooms[room] ||= p['id']
        end
      end

      def project_id_from_name( name )
        return name if name.to_s =~ /^[0-9]+$/

        projects.each do |project|
          return project['id'] if project['name'].projectize == name.projectize
        end

        puts "Couldn't find project #{name.projectize}"
        nil
      end

      def project( id )
        auth_token
        data = self.class.get "/projects/#{id}.json"

        data['orchard_config'] ||= {}
        data['orchard_config']['teams'] ||= []

        data
      end

      def lookup_user( query )
        auth_token
        self.class.get "/users/lookup.json", { query: query }
      end

      def search_users( query )
        auth_token
        self.class.get "/users/search.json", { query: query}
      end

      def organization_users( id )
        auth_token
        self.class.get "/organizations/#{id}/users.json"
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

      def environments( id )
        auth_token
        self.class.get "/projects/#{id}/environments.json"
      end


      def check( id )
        auth_token
        f = feeds( id ).group_by{|x| x['feed_name']}
        e = environments( id ).group_by{|x| x['name'].downcase}

        status = {
          sourcecontrol: {passed: true, messages: []},
          servers: {passed: true, messages: []},
          bugtracking: {passed: true, messages: []},
          environments: {passed: true, messages: []}
        }

        # Check for heroku apps
        if f['github'].nil?
          status[:sourcecontrol][:passed] = false
          status[:sourcecontrol][:messages] << 'No source control is set up'
        else
          status[:sourcecontrol][:passed] = true
        end

        # Check for heroku apps
        if f['heroku'].nil?
          status[:servers][:passed] = false
          status[:servers][:messages] << 'No heroku app is set up'
        else
          status[:servers][:passed] = true
        end


        # Check for asana or lighthouse tracking:
        if f['asana'].nil? and f['lighthouse'].nil?
          status[:bugtracking][:passed] = false
          status[:bugtracking][:messages] << 'No bugtracking is set up'
        else
          status[:bugtracking][:passed] = true
        end


        # Check for environments:
        if e['production'].nil?
          status[:environments][:passed] = false
          status[:environments][:messages] << "No 'production' environment is set up"
        end

        if e['staging'].nil?
          status[:environments][:passed] = false
          status[:environments][:messages] << "No 'staging' environment is set up"
        end

        status
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
        activities_stats activities, after, before # <-- so activities actually returns activities_stats? That's... weird.
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

      def heroku_api( token = nil )
        auth_token
        ret = {}
        if( token )
          ret = self.class.post "/organizations/1/heroku/api_token.json", {query: {heroku_api_token: token}}
        else
          ret = self.class.get "/organizations/1/heroku/api_token.json"
        end
        ret['heroku_api_token']
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

          raise Exceptions::LoginAuthenticationFailure if response['auth_token'].nil?

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
        if ENV['JUICE_AUTH_TOKEN'].nil?
          begin
            query_login
          rescue Exceptions::AlreadyLoggedIn
          end
        else
          @options = { 'auth_token' => ENV['JUICE_AUTH_TOKEN'] }
        end
        self.class.default_params auth_token: @options['auth_token']
        @options['auth_token']
      end

    end
  end
end
