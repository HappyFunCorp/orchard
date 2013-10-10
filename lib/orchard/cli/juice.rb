module Orchard
  module CLI
    class Juice < Thor
      desc "login", "Login to juice"
      def login
        puts "Logged in." if client.login
      end

      desc "logout", "Clear juice credentials"
      def logout
        puts "Juice credentials cleared." if client.logout
      end

      desc "open [PROJECT]", "Open up juice"
      def open( name )
        project_id = project_id_from_name name
        if( project_id.nil? )
          puts "#{name} not found"
          return
        end

        system "open http://happyfunjuice.com/projects/#{project_id}"
      end

      desc "settings [PROJECT]", "Open up juice settings"
      def settings(name)
        project_id = project_id_from_name name
        if( project_id.nil? )
          puts "#{name} not found"
          return
        end

        system "open http://happyfunjuice.com/projects/#{project_id}/overview"
      end

      desc "create [PROJECT]", "Create a juice project"
      def create( name )
        puts "TIP: you can also run check #{name} to set up everything"
        client.create_project( name )
      end

      desc "projects", "List juice projects"
      def projects
        puts
          printf "%-25s %-10s %-10s %-25s\n".blue, '', 'Commits', 'Deploys', '', ''
          printf "%-25s %-10s %-10s %-25s\n".blue, '', 'this', 'this', '', ''
          printf "%-25s %-10s %-10s %-25s\n".underline.blue, 'Name', 'wk', 'wk', 'Hipchat room', 'Teams'
        client.summary.sort{|a,b| b['name'].to_i <=> a['name'].to_i}.each_with_index do |project,i|
          printf "%-25s %-10s %-10s %-25s\n".try{|x| i%4==3 ? x.underline : x}, 
            #project['id'], 
            project['name'].projectize, 
            (project['has_source_feeds'] ? project['commits_this_week'] : ''),
            (project['has_server_feeds'] ? project['deploys_this_week'] : ''),
            project['orchard_config']['hipchat_room'],
            project['orchard_config']['teams'].join( ',' )
        end
        puts
      end

      # Alias for 'info' command
      desc "project [NAME]", "Get project metadata"
      def project( name )
        self.class.new.info( name )
      end


      desc "info [NAME]", "Get project metadata"
      def info( name )
        puts
        puts 'Info:'.bold
        puts
        project_id = project_id_from_name name
        if( project_id.nil? )
          puts "#{name} not found"
          return
        end

        data = client.project( project_id_from_name( name ) )
        puts "Name".blue + "      : #{data['name']} (#{data['name'].projectize})"
        puts "ID".blue + "        : #{data['id']}"
        puts "Hipchat".blue + "   : #{data['orchard_config']['hipchat_room']}"
        puts "Teams".blue + "     : #{data['orchard_config']['teams'].join( ',' )}"

        puts

        repos = []
        data['orchard_config']['teams'].each do |team|
          puts "Team #{team}:".bold
          Orchard::CLI::Github.new.team( team )
          github_client.list_team_repos( team ).each do |repo|
            repos << repo['full_name']
            #printf "Repo".blue + "      : %-40s %s\n", repo['full_name'], repo['description']
          end
          #github_client.list_team_members( team ).each do |user|
            #printf "User".blue + "      : %s\n", user['login']
          #end
        end

        puts 'Github Hooks:'.bold
        repos.each do |repo|
          Orchard::CLI::Github.new.hooks( repo )
        end
        data
      end

      desc "organizations", "Get a list of your organizations"
      def organizations
        puts
        printf "%-5s %-25s %-25s\n".underline.blue, 'ID', 'Name', 'Domain name'
        client.organizations.each do |o|
          printf "%-5s %-25s %-25s\n", o['id'], o['name'], o['domain_name']
        end
        puts
      end
        

      desc "feeds [PROJECT]", "Show the configured juice feeds"
      def feeds(name)
        puts
        printf "%-30s %-20s %-30s\n".blue.underline, 'Feed', 'Environment', 'Namespace'
        client.feeds( project_id_from_name( name ) ).sort do
          |a,b| a['feed_name'] <=> b['feed_name']
        end.each do |feed|
          printf "%-30s %-20s %-30s\n", 
            feed['feed_name'], 
            (feed['environment'] || {})['name'],
            [feed['namespace'],feed['name']].select {|x| x}.join( '/' )
        end
        puts
      end

      desc "users [PROJECT (optional)]", "Get a list of users"
      def users( name=nil )

        if name.nil?
          _users = client.organization_users( 1 ) # Hard-code hfc org here
        else
          _users = client.project_users( project_id_from_name( name ) )
        end

        puts
        printf "%-25s %35s %35s %35s %35s\n".blue.underline, 'Name', 'Email', 'Personal email', 'Heroku', 'Github'
        _users.each do |u|
          printf "%-25s %35s %35s %35s %35s\n", u['name'], u['email'], u['personal_email'], u['heroku_handle'], u['github_handle']
        end
        puts
      end

      desc "add_team [PROJECT] [TEAM]", "Add a github team to a project"
      def add_team( name, team )
        client.project_add_team( project_id_from_name( name ), team )
        info( name )
      end

      desc "add_hipchat [PROJECT] [ROOM]", "Add a hipchat room to a project"
      def add_hipchat( name, room )
        client.project_add_hipchat( project_id_from_name( name ), room )
        info( name )
      end

      desc "lookup_user [EMAIL]", "Looks up a user by email address"
      def lookup_user( email )
      end

      desc "search_users [QUERY]", "Look up a user by name, email, github, heroku, etc."
      def search_users( query )
        puts
        printf "%-25s %35s %35s %35s %35s\n".blue.underline, 'Name', 'Email', 'Personal email', 'Heroku', 'Github'
        client.search_users(query).each do |u|
          printf "%-25s %35s %35s %35s %35s\n", u['name'], u['email'], u['personal_email'], u['heroku_handle'], u['github_handle']
        end
        puts
      end

      desc "user_set [FIELD] [VALUE]", "Set the value of a particular field for a user"
      def user_set( field, value )
        client
      end

      desc "hipchat_api [TOKEN]", "Sets the organization hipchat token"
      def hipchat_api( token )
        client.hipchat_api token
      end

      desc "check [PROJECT]", "Check a project config (all the checks)"
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

      desc "check_project [PROJECT]", "Check to see if a project exists"
      def check_project( name )
        puts "Looking for project #{name}".bold
        project_id = project_id_from_name name

        if project_id.nil?
          choose do |menu|
            menu.header = "No juice project found".red

            menu.prompt = "Create?"

            menu.choice "create" do
              client.create_project name
            end

            menu.choice "ignore"
          end
        else
          puts "Juice project found".green
        end
      end

      desc "check_hipchat [PROJECT]", "Check to see if hipchat is configured"
      def check_hipchat(name)
        begin
          puts "Looking to see if hipchat is configured".bold
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
            puts "Hipchat room not set".yellow

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
              puts "Creating a room #{name}"
              Orchard::Client.hipchat_client.create_room( name, "Let's talk about #{name}!" )
              add_hipchat name, name
            elsif set( room )
              add_hipchat name, room
            end
          end
        rescue Exceptions::HipchatAuthenticationFailure
          puts "Error communicating with Hipchat. Is your key valid?".red
        end
      end

      desc "check_team [PROJECT]", "Check to see if github team is configured"
      def check_team(name)
        begin
          puts "Looking to see if github team is configured".bold
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
            puts "No teams set".yellow

            team = choose do |menu|
              menu.header = "Select a github team"
              menu.prompt = "Please select a team"

              menu.choice "Create a new team" do
                "create"
              end

              menu.choices *github_client.list_teams.collect { |x| x.name }
            end

            if team == "create"
              puts "Creating team: #{name}"
              pp github_client.create_team( name )
              add_team( name, team )
            elsif set( team )
              add_team( name, team )
            end
          end
        rescue RuntimeError => e
          puts "Error communicating with github".red
          puts Exceptions.formatted(e)
        end
      end

      desc "check_bugtracking [PROJECT]", "Check to see if bugtracking is configured"
      def check_bugtracking
        puts "Looking to see if bugtracking is configured".bold
        project_id = project_id_from_name name
        return if project_id.nil?

        data = client.project project_id
        config = data['orchard_config']

        ##
        # Bugtracking
        ##

        puts "TODO Check bug tracking"
      end

      desc "check_hooks [PROJECT]", "Check to see if the hooks are configured"
      def check_hooks( name )
        puts "Looking for github hooks".bold
        ##
        # Github Hooks
        ##
        project_id = project_id_from_name name
        return if project_id.nil?

        data = client.project project_id
        config = data['orchard_config']

        teams = config['teams']

        if teams.count > 0
          teams.each do |team|
            puts "Looking at repos for #{team}".bold
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
        else
          puts "Teams must be set up correctly in order to monitor hooks.".red
        end
      end

      desc "hipchat_check", "Prints out all the rooms not assigned to rooms"
      def hipchat_check
        begin
          client.hipchat_check.each do |x|
            printf "%-30s %s\n", x[:room], x[:projects].join( "," )
          end
        rescue Exceptions::HipchatAuthenticationFailure
          puts "Unable to connect to Hipchat. Is your key valid?".red
        end
      end

      desc "github_check", "Prints out all teams not assigned to a project"
      def github_check
        puts "github check: TODO"
      end

      desc "activity [PROJECT]", "Shows recent project activity in last week or (default) current week [--lastweek] [--thisweek]"
      option :lastweek
      option :thisweek
      def activity( name )
        puts
        project_id = project_id_from_name name
        return if project_id.nil?

        now = DateTime.now.to_date + 1
        after = now - now.wday
        before = Time.now

        if( options[:lastweek] )
          after -= 7
          before = after + 7
        end

        summary = client.activities( project_id, after.to_time, before.to_time )

        summary

        puts "#{name} activity".bold + " for #{summary[:after].strftime( "%Y-%m-%d %H:%M" )} (#{((Time.now-summary[:after])/3600/24).ceil} days ago) - #{summary[:before].strftime( "%Y-%m-%d %H:%M" )} (now)"
        puts
        puts "Activity Summary".underline.blue
        summary[:type].keys.sort.each do |x|
          printf "%-6s %s\n", summary[:type][x].count, x
        end

        puts
        puts "Activity Breakdown".underline.blue
        summary[:actors_activites].keys.sort.each do |x|
          summary[:actors_activites][x].keys.select { |x| x}.sort.each do |type|
            printf "%-6s %-25s %s\n", summary[:actors_activites][x][type].count, type.strip_email, x
          end
        end

        puts
        puts "New Tickets".underline.blue
        (summary[:type]['bugtracking:openticket'] || []).each do |activity|
          puts activity['description'][0..100].gsub( /\n/, " " )
        end

        puts
        puts "Closed Tickets".underline.blue
        (summary[:type]['bugtracking:closedticket'] || []).each do |activity|
          puts activity['description'][0..100].gsub( /\n/, " " )
        end

        puts
        puts "Active Tickets".underline.blue
        summary[:type].keys.select do |x|
          x =~ /bugtracking/
        end.collect do |x|
          summary[:type][x].collect do |a|
            a['description']
          end
        end.flatten.sort.uniq.each do |x|
          puts x[0..100].gsub( /\n/, " " ) unless x =~ /^\[Changeset\]/
        end

        puts
        puts "Commits".underline.blue
        (summary[:type]['sourcecontrol:commit'] || []).each do |x|
          printf "%-30s %s\n", x['actor_identifier'].strip_email, x['description'][0..100].gsub( /\n/, " " )
        end
      end

      desc "report", "Because report_dump is weird"
      def report(name)
        _p = project_id_from_name( name )
        info _p
        activity _p
      end

      desc "report_dump", "Write out weekly reports"
      option :lastweek
      def report_dump
        puts "Loading projects"

        system "mkdir -p /tmp/juice_reports"
        client.projects.each do |project|
          File.open( "/tmp/juice_reports/#{project['name']}.txt", "w" ) do |out|
            puts "Running report for #{project['name']}"
            $stdout = out
            info project['name']
            activities project['name']
            $stdout = STDOUT
          end
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
