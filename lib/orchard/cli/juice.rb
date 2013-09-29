module Orchard
  module CLI
    class Juice < Thor
      desc "login", "Login to juice"
      def login
      end

      desc "open NAME", "Open up juice"
      def open( name )
        project_id = project_id_from_name name
        if( project_id.nil? )
          puts "#{name} not found"
          return
        end

        system "open http://happyfunjuice.com/project/#{project_id}"
      end

      desc "settings NAME", "Open up juice settings"
      def settings(name)
        project_id = project_id_from_name name
        if( project_id.nil? )
          puts "#{name} not found"
          return
        end

        system "open http://happyfunjuice.com/project/#{project_id}/overview"
      end

      desc "create NAME", "Create a juice project"
      def create( name )
        puts "TIP: you can also run check #{name} to set up everything"
        client.create_project( name )
      end

      desc "projects", "List juice projects"
      def projects
        client.projects.each do |project|
          printf "%-5s %-25s %-10s %s\n", 
            project['id'], 
            project['name'], 
            project['orchard_config']['hipchat_room'],
            project['orchard_config']['teams'].join( ',' )
        end
      end

      desc "info name", "Get project meta data"
      def info( name )
        project_id = project_id_from_name name
        if( project_id.nil? )
          puts "#{name} not found"
          return
        end

        data = client.project( project_id_from_name( name ) )
        puts "Name      : #{data['name']}"
        puts "ID        : #{data['id']}"
        puts "Hipchat   : #{data['orchard_config']['hipchat_room']}"
        puts "Teams     : #{data['orchard_config']['teams'].join( ',' )}"

        repos = []
        data['orchard_config']['teams'].each do |team|
          puts "TEAM #{team}"
          github_client.list_team_repos( team ).each do |repo|
            repos << repo['full_name']
            printf "Repo: %-40s %s\n", repo['full_name'], repo['description']
          end
          github_client.list_team_members( team ).each do |user|
            printf "User: %s\n", user['login']
          end
        end
        repos.each do |repo|
          Orchard::CLI::Github.new.hooks( repo )
        end
        data
      end

      desc "feeds name", "Show the configured juice feeds"
      def feeds(name)
        client.feeds( project_id_from_name( name ) ).sort do
          |a,b| a['feed_name'] <=> b['feed_name']
        end.each do |feed|
          printf "%-15s %-12s %s\n", 
            feed['feed_name'], 
            (feed['environment'] || {})['name'],
            [feed['namespace'],feed['name']].select {|x| x}.join( '/' )
        end
      end

      desc "users NAME", "Get a list of project users"
      def users( name )
        pp client.project_users( project_id_from_name( name ) )
      end

      desc "add_team NAME TEAM", "Add a github team to a project"
      def add_team( name, team )
        client.project_add_team( project_id_from_name( name ), team )
        info( name )
      end

      desc "add_hipchat NAME ROOM", "Add a hipchat room to a project"
      def add_hipchat( name, room )
        client.project_add_hipchat( project_id_from_name( name ), room )
        info( name )
      end

      desc "lookup_user EMAIL", "Looks up a user by email address"
      def lookup_user( email )
      end

      desc "hipchat_api TOKEN", "Sets the organization hipchat token"
      def hipchat_api( token )
        client.hipchat_api token
      end

      desc "check NAME", "Check a project config (all the checks)"
      def check( name )
        check_project( name )
        puts
        check_hipchat( name )
        puts
        check_team( name )
        puts
        check_hooks( name )
        puts
        info( name )
      end

      desc "check_project NAME", "Check to see if a project exists"
      def check_project( name )
        puts "Looking for project #{name}"
        project_id = project_id_from_name name

        if project_id.nil?
          choose do |menu|
            menu.header = "No juice project found"

            menu.prompt = "Create?"

            menu.choice "create" do
              client.create_project name
            end

            menu.choice "ignore"
          end
        else
          puts "Juice project found"
        end
      end

      desc "check_hipchat NAME", "Check to see if hipchat is configured"
      def check_hipchat(name)
        puts "Looking to see if hipchat is configured"
        project_id = project_id_from_name name
        return if project_id.nil?

        data = client.project project_id
        config = data['orchard_config']

        if( set( config['hipchat_room'] ) )
          puts "Hipchat Room Configured: #{config['hipchat_room']}"
          room = hipchat_client.room_info config['hipchat_room']
          if room.nil?
            choose do |menu|
              menu.header = "Juice has the name configured, but can't find hipchat room named #{config['hipchat_room']}"
              menu.prompt = "Create or ignore"

              menu.choice "create" do
                hipchat_client.create_room( config['hipchat_room'], "Let's talk about #{config['hipchat_room']}!" )
              end

              menu.choice "ignore"
            end
          else
            puts "Hipchat exists: #{config['hipchat_room']}"
          end
        else
          puts "Hipchat room not set"

          choices = client.hipchat_check.select do |x|
            x[:projects].first == "_unassigned_"
          end.collect do |x|
            x[:room]
          end

          if choices.member? name
            puts "Found a matching room... attaching"
            add_hipchat name, name
            return
          end

          room = choose do |menu|
            menu.header = "Select a hipchat room action"
            menu.prompt = "Please choose a unassigned hipchat room to associate"
            menu.choice "Create A Room called #{name}" do
              "create"
            end

            menu.choices *choices
          end

          puts "You chose: #{room}"

          if room == "create"
            puts "Creating a room #{room}"
            Orchard::Client.hipchat_client.create_room( room, "Let's talk about #{room}!" )
          elsif set( room )
            add_hipchat name, room
          end
        end
      end

      desc "check_team NAME", "Check to see if github team is configured"
      def check_team(name)
        puts "Looking to see if github team is configured"
        project_id = project_id_from_name name
        return if project_id.nil?

        data = client.project project_id
        config = data['orchard_config']

        ##
        # Github teams
        ##

        if( config['teams'].size != 0 )
          puts "Team: #{config['teams'].join( ',' )}"
        else
          puts "No teams set"

          team = choose do |menu|
            menu.header = "Select a github team"
            menu.prompt = "Please select a team"

            menu.choice "Create a new team" do
              "create"
            end

            menu.choices *github_client.list_teams.collect { |x| x.name }
          end

          if set( team )
            add_team( name, team )
          end
        end
      end

      desc "check_bugtracking NAME", "Check to see if bugtracking is configured"
      def check_bugtracking
        puts "Looking to see if bugtracking is configured"
        project_id = project_id_from_name name
        return if project_id.nil?

        data = client.project project_id
        config = data['orchard_config']

        ##
        # Bugtracking
        ##

        puts "TODO Check bug tracking"
      end

      desc "check_hooks NAME", "Check to see if the hooks are configured"
      def check_hooks( name )
        puts "Looking for github hooks"
        ##
        # Github Hooks
        ##
        project_id = project_id_from_name name
        return if project_id.nil?

        data = client.project project_id
        config = data['orchard_config']

        config['teams'].each do |team|
          puts "Looking at repos for #{team}"
          github_client.list_team_repos( team ).each do |repo|
            printf "%-40s %s\n", repo['full_name'], repo['description']
            found = {}
            github_client.list_hooks( repo['full_name'] ).each do |hook|
              puts "Found #{hook["name"]}"
              found[hook['name']] = true
            end

            unless found['hipchat']
              puts "Missing hipchat hook"
              if config['hipchat_room']
                puts "Adding Hipchat Hook"
                Orchard::CLI::Github.new.add_hipchat( repo['full_name'], config['hipchat_room'])
              else
                puts "Missing hipchat room"
              end
            end
          end
        end
      end

      desc "hipchat_check", "Prints out all the rooms not assigned to rooms"
      def hipchat_check
        client.hipchat_check.each do |x|
          printf "%-30s %s\n", x[:room], x[:projects].join( "," )
        end
      end

      no_commands do
        def client
          @client ||= Orchard::Client.juice_client
        end

        def hipchat_client
          Orchard::Client.hipchat_client
        end

        def github_client
          Orchard::Client.github_client
        end

        def project_id_from_name( name )
          client.project_id_from_name( name )
        end

        def set( s )
          !s.nil? && s != ""
        end
      end
    end
  end
end