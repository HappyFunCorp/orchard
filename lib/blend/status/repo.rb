module Blend
  module Status
    class Repo
      attr_accessor :project, :name, :repo

      def initialize( project, name, repo)
        @project = project
        @name = name
        @repo = repo
      end

      def github_client
        Blend::Client.github_client
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

      def resolve_hipchat_hook
        puts "Adding hipchat hook...".yellow
        Blend::CLI::Github.new.add_hipchat( repo['full_name'], @project.hipchat ) if @project.hipchat
      end

      def check key, method
        ret = __send__( method )
        ret = false if ret.nil?
        printf "%20s: ", key
        if( ret )
          printf "\u2713\n".encode('utf-8').green
        else
          printf "\u2718\n".encode('utf-8').red

          if( @project.resolve )
            r = "resolve_#{method}".to_sym
            __send__(r) if respond_to? r
          end
        end
      end

    end
  end
end