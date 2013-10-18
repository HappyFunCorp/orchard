require 'orchard/status/team'
require 'orchard/status/repo'
require 'orchard/status/domain'
require 'orchard/status/environment'

module Orchard
  module Status
    class Project
      attr_accessor :name, :juice_id

      def initialize( name, resolve = false )
        @name = name
        @juice_client = Orchard::Client.juice_client
        @juice_id = @juice_client.project_id_from_name @name
      end


      def team_status
        @teams ||= (github_teams || []).collect do |team|
          Team.new( self, team )
        end
      end

      def repo_status
        @repos ||= (repos || []).collect do |name, repo|
          Repo.new( self, name, repo )
        end
      end

      def environment_status
        @environment_status ||= (servers || []).collect do |server|
          Environment.new( self, server['name'], server['environment']['name'].downcase )
        end
      end

      def domains_status
        @domains_status ||= domains.collect do |x|
          Domain.new( @project, x[:environment], x[:domain] )
        end
      end

      def domains
        environment_status.collect do |x| 
          x.domains.collect do |domain|
            {environment: x.environment, domain: domain }
          end
        end.flatten
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

      def read_only_teams
        team_status.select { |team| team.read_only? }
      end

      def write_teams
        team_status.select { |team| !team.read_only? }
      end

      def github_members
        read_only_members = read_only_teams.collect { |ts| ts.members }.flatten
        write_team_members = write_teams.collect { |ts| ts.members }.flatten

        read_only_members -= write_team_members

        write_team_members.collect do |x| 
          {name: x, access: :full}
        end + read_only_members.collect do |x| 
          {name: x, access: :read}
        end
      end

      def repos
        ret = {}
        team_status.each do |x|
          x.repos.each do |repo|
            ret[repo.full_name] = repo
          end
        end
        ret
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
        # return []] if @juice_id.nil?
        return [] if config.nil?
        config['teams'] 
      end

      def header text
        puts
        puts "#{text}".blue.underline
      end

      def check key, method
        ret = __send__( method )
        ret = false if ret.nil?
        ret = false if ret.is_a? Array and ret.length == 0
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