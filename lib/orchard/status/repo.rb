module Orchard
  module Status
    class Repo
      attr_accessor :project, :name, :repo

      def initialize( project, name, repo)
        @project = project
        @name = name
        @repo = repo
      end

      def github_client
        Orchard::Client.github_client
      end

      def private?
        @repo['private']
      end

      def hooks
        @hooks ||= github_client.list_hooks( repo['full_name'] ).group_by { |x| x['name'] }
      end

      def hipchat_hook
        hooks['hipchat']
      end

      def check key, method
        ret = __send__( method )
        ret = false if ret.nil?
        printf "%20s: ", key
        if( ret )
          printf "\u2713\n".encode('utf-8').green
        else
          printf "\u2718\n".encode('utf-8').red
        end
      end

    end
  end
end