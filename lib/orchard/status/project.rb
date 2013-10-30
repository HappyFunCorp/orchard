require 'orchard/status/team'
require 'orchard/status/repo'
require 'orchard/status/domain'
require 'orchard/status/environment'
require 'orchard/status/project_resolver'

module Orchard
  module Status
    class Project
      attr_accessor :name, :juice_id, :juice_client, :resolve

      def initialize( name, resolve = false )
        @name = name
        @juice_client = Orchard::Client.juice_client
        reload
        @resolve = resolve
        @resolver = ProjectResolver.new( self )
      end

      def reload
        @juice_id = @juice_client.project_id_from_name @name
        @teams = nil
        @repos = nil
        @environment_status = nil
        @domains_status = nil
        @config = nil
        @feeds = nil
        @environments = nil
      end


      ##
      # Sub status systems
      ##

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

      ##
      # Project Metadata
      ##

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

      ##
      # Checks
      ##

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

      def repos_setup
        repos.keys
      end

      def source_control
        a = (feeds['github'] || []).collect { |x| "#{x['namespace']}/#{x['name']}" }
        b = repos_setup

        return false if (a-b).length != 0 || (b-a).length != 0
        return false if a.length == 0 || b.length == 0
        return a
      end

      def juice_users_synced_diff
        team_juice_users = {}
        github_members.each do |member|
          user = juice_client.user_from_github_user member[:name]
          team_juice_users[user['id']] = user if user
        end

        juice_users = juice_client.project_users( @juice_id ).group_by{ |x| x['id'] }

        not_in_juice = team_juice_users.keys - juice_users.keys
      end

      def juice_users_synced
        juice_users_synced_diff.length == 0
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

        pass = ret

        if ret.is_a? Array
          ret = ret.collect do |x|
            if x.is_a? Hash
              x[:name] || x['name']
            else
              x
            end
          end.join( ", ")
        end

        ret = "" if !ret

        printf "%20s: ", key
        if( pass )
          printf "\u2713 #{ret}\n".encode('utf-8').green
        else
          printf "\u2718 #{ret}\n".encode('utf-8').red
          if @resolve
            r = "resolve_#{method}".to_sym
            @resolver.__send__(r) if @resolver.respond_to? r
            reload
          end
        end
      end
    end
  end
end