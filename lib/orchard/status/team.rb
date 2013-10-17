module Orchard
  module Status
    class Team
      attr_accessor :name

      def initialize( project, name )
        @project = project
        @name = name
      end

      def github_client
        Orchard::Client.github_client
      end

      def repos
        @repos ||= github_client.list_team_repos @name
      end

      def members
        @members ||= github_client.list_team_members( @name ).collect { |x| x['login'] }
      end

      def read_only?
        @github_team ||= github_client.list_team @name
        return @github_team && @github_team['permission'] != 'push'
      end
    end
  end
end