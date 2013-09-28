module Orchard
  module CLI
    class Github < Thor
      desc "hooks REPO", "Lists out service hooks for a given repo"
      def hooks( repo )
        client.list_hooks( repo ).each do |hook|
          printf "%-20s %s\n", hook.name, hook.config
        end
      end

      desc "add_hipchat REPO ROOM", "Add hipchat hook to repo"
      def add_hipchat( repo, room )
        client.add_hook( repo, "hipchat", { 
          auth_token: Orchard::Client::get_token( :hipchat ), 
          notify: "1",
          restrict_to_branch: "",
          room: room } )
        Orchard::Client::hipchat_client.post_message room, "#{repo} commit hook now added"
      end

      desc "repos", "Lists out the repos"
      def repos
        client.list_repos.each do |repo|
          printf "%-40s %s\n", repo['full_name'], repo['description']
        end
      end

      desc "repo_search NAME", "Lists out matching repos"
      def repo_search( name )
        client.list_repos(name).each do |repo|
          printf "%-40s %s\n", repo['full_name'], repo['description']
        end
      end

      desc "repo_create TEAM, NAME", "Create team repo"
      def repo_create( team, name )
        client.repo_create( team, name )
        team( team )
      end


      desc "collaborators REPO", "List out collaborators"
      def collaborators( repo )
        client.list_collaborators( repo ).each do |collaborator|
          puts collaborator['login']
        end
      end

      desc "teams", "List out organizations team"
      def teams
        client.list_teams.each do |team|
          puts team.name
        end
      end

      desc "team_repos TEAM", "List out a teams repos"
      def team_repos( team )
        client.list_team_repos( team ).each do |repo|
          printf "%-40s %s\n", repo['full_name'], repo['description']
        end
      end

      desc "team TEAM", "List out the team"
      def team( team )  
        client.list_team_repos( team ).each do |repo|
          printf "Repo: %-40s %s\n", repo['full_name'], repo['description']
        end
        client.list_team_members( team ).each do |user|
          printf "User: %s\n", user['login']
        end
      end

      desc "team_create TEAM", "Create a team"
      def team_create( team )
        client.create_team( team )
        team( team )
      end
      
      desc "team_add TEAM, USER", "Add a user to a team"
      def team_add( team, user )
        client.add_team_member( team, user )
        team( team )
      end

      desc "team_rm TEAM, USER", "Remove a user from a team"
      def team_rm( team, user)
        client.remove_team_member( team, user )
        team( team )
      end

      desc "team_repo_add TEAM, REPO", "Add a repo to a team"
      def team_repo_add( team, repo )
        client.add_team_repo( team, repo )
        team( team )
      end

      desc "team_repo_rm TEAM, REPO", "Remove a repo from a team"
      def team_repo_rm( team, repo )
        client.remove_team_repo( team, repo )
        team( team )
      end

      no_commands do
        def client
          @client ||= Orchard::Client.github_client
        end
      end

    end
  end
end