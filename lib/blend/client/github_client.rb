module Blend
  module Client
    class GithubClient
      attr_accessor :client

      def initialize( client )
        @client = client
      end

      def list_repos( filter = nil )
        return @repos if @repos && filter.nil?

        repos = []
        @client.repos.list( org: "sublimeguile" ).each_page do |page|
          page.each do |r|
            repos << r
          end
        end

        if filter
          repos = repos.select { |x| x['name'] =~ /#{filter}/ }
        end

        repos = repos.sort do |a,b| 
          a['name'] <=> b['name']
        end

        @repos = repos if filter.nil?
        repos
      end

      def repo_create( team, name )
        require 'pp'
        pp @client.repos.create org: "sublimeguile", name: name, public: false, private: true
        add_team_repo( team, "sublimeguile/#{name}" )
      end


      def list_collaborators( repo )
        @client.repos.collaborators.list *repo.split( /\// )
      end

      def list_hooks( repo )
        @client.repos.hooks.list( *repo.split( /\// ) )
      end

      def add_hook( repo, name, config )
        @client.repos.hooks.create *repo.split( /\// ), name: name, config: config
      end

      def list_teams
        @client.orgs.teams.list "sublimeguile"
      end

      def find_team_from_name( name )
        list_teams.select { |x| x['name'] == name }
      end

      def list_team( team )
        find_team_from_name( team ).first
      end

      def list_team_repos( team )
        find_team_from_name(team).each do |x|
          return @client.orgs.teams.repos x.id
        end
      end

      def list_team_members( team )
        find_team_from_name(team).each do |x|
          return @client.orgs.teams.list_members x.id
        end
      end

      def create_team( team )
        @client.orgs.teams.create "sublimeguile", { name: team, permission: "push" }
      end

      def add_team_member( team, user )
        find_team_from_name( team ).each do |x|
          return @client.orgs.teams.add_member x.id, user
        end
      end

      def remove_team_member( team, user)
        find_team_from_name( team ).each do |x|
          return @client.orgs.teams.remove_member x.id, user
        end
      end

      def add_team_repo( team, repo )
        user,name = repo.split( /\// )
        find_team_from_name( team ).each do |x|
          return @client.orgs.teams.add_repo x.id, user, name
        end
      end

      def remove_team_repo( team, repo )
        user,name = repo.split( /\// )
        find_team_from_name( team ).each do |x|
          return @client.orgs.teams.remove_repo x.id, user, name
        end
      end
    end
  end
end
