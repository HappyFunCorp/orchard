module Orchard
  module Status
    class ProjectResolver
      attr_accessor :project

      def initialize( project )
        @project = project
      end

      def juice_client
        @project.juice_client
      end

      def github_client
        Orchard::Client.github_client
      end

      def name
        @project.name
      end

      def set( s )
        !s.nil? && s != ""
      end

      def resolve_project_found
        puts "Trying to fix project_found"

        choose do |menu|
          menu.header = "No juice project found".red

          menu.prompt = "Create?"

          menu.choice "create" do
            juice_client.create_project @name
          end

          menu.choice "ignore"
        end
      end

      def resolve_hipchat
        puts "Resolve hipchat"

        choices = juice_client.hipchat_check.select do |x|
          x[:projects].first == "_unassigned_"
        end.collect do |x|
          x[:room]
        end

        if choices.member? name
          puts "Found a matching room... attaching"
          juice_client.project_add_hipchat( @project.juice_id, name )
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
          room = name
          puts "Creating a room #{name}"
          Orchard::Client.hipchat_client.create_room( name, "Let's talk about #{name}!" )
        end

        if( set( room ) )
          juice_client.project_add_hipchat( @project.juice_id, name )
        end
      end

      def resolve_github_teams
        team = choose do |menu|
          menu.header = "Select a github team"
          menu.prompt = "Please select a team"

          menu.choice "Create a new team" do
            "create"
          end

          menu.choices *Orchard::Client.juice_client.github_team_check.select { |k,v| v.length == 0}.keys
        end

        if team == "create"
          team = name.downcase
          puts "Creating team: #{name}"
          pp github_client.create_team( name.downcase )
        end

        if( set( team ))
          juice_client.project_add_team( @project.juice_id, team )
        end
      end

      def resolve_repos_setup
        teams = @project.github_teams

        if teams.length == 0
          puts "Need to have a github team configured to create a repo".red
          return
        end

        team = teams.first

        repos = @project.repos

        [ "", "-ios", "-android" ].each do |suffix|
          repo_name = "#{name}#{suffix}".downcase
          if repos.collect { |k,v| v }.select { |x,v| x['name'] == repo_name}.length > 0
            puts "Found #{repo_name}".green
          elsif agree "Create #{repo_name}? y/n ", true
            puts "Creating #{repo_name} in team #{team}".yellow
            github_client.repo_create( team, repo_name )
          end
        end
      end

      def resolve_source_control
        repos = @project.repos_setup
        configured = (@project.feeds['github'] || []).collect { |x| "#{x['namespace']}/#{x['name']}" }

        (repos-configured).each do |repo|
          # TODO
          puts "Need to wire up #{repo}".yellow
        end
      end

      def resolve_github_members
        people = juice_client.organization_users(1).collect { |x| { name: x["name"], github: x['github_handle']}}.select { |x| set(x[:github]) }
        teams = @project.github_teams

        if teams.length == 0
          puts "Need to have a github team configured to add people to it!".red
          return
        end

        team = teams.first

        github = ""

        begin
          user = choose do |menu|

            menu.header = "Select a user"
            menu.prompt = "Please select a user"

            menu.choice "Done" do
              "done"
            end

            menu.choices *people.sort{|a,b| a[:name] <=> b[:name]}.collect { |x| "#{x[:github]}:#{x[:name]}"}
          end

          github = user.split( /:/ ).first

          if github != "done"
            github_client.add_team_member team, github
          end
        end while github != "done"
      end

      def resolve_juice_users_synced
        not_in_juice = @project.juice_users_synced_diff

        not_in_juice.each do |user_id|
          puts "Adding juice user_id: #{user_id}".yellow

          juice_client.project_add_user( @project.juice_id, user_id )
        end
      end
    end
  end
end