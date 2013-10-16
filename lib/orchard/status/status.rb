require 'orchard/status/team'
require 'orchard/status/environment'

module Orchard
  module Status
    class Status
      attr_accessor :name, :juice_id

      def initialize( name, resolve = false )
        @name = name
        @juice_client = Orchard::Client.juice_client
        @juice_id = @juice_client.project_id_from_name @name
      end


      def team_status
        (github_teams || []).collect do |team|
          Team.new( self, team )
        end
      end

      def repo_status
        # TODO
        []
      end

      def environment_status
        # TODO
        []
      end

      def config
        @config ||= (@juice_client.project( @juice_id ) || {})['orchard_config']
      end

      def feeds
        @feeds ||= @juice_client.feeds( @juice_id ).group_by { |x| x['feed_name'] }
      end

      def environments
        @environments ||= @juice_client.environments( @juice_id ).group_by{|x| x['name'].downcase}
      end

      def project_found
        !@juice_id.nil? && @juice_id != ""
      end

      def source_control
        feeds['github']
      end

      def servers( env = nil )
        if( env )
          (feeds['heroku'] || []).group_by { |x| x['environment']['name'].downcase }[env]
        else
          feeds['heroku']
        end
      end

      def bugtracking
        f = (feeds['asana'] || []) + (feeds['lighthouse'] || [])
        return nil if f.length == 0
        f
      end

      def production
        environments['production']
      end

      def staging
        environments['staging']
      end

      def heroku_apps( env = nil )
        servers(env).collect { |x| [x['name'], x['environment']['name']]}
      end

      def hipchat
        return nil if config.nil?
        config['hipchat_room']
      end

      def github_teams
        return nil if config.nil?
        config['teams'] 
      end

      def header text
        puts
        puts "#{text}".blue.underline
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