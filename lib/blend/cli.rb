require 'blend/cli/hipchat'
require 'blend/cli/github'
require 'blend/cli/juice'
require 'blend/cli/heroku'

module Blend
  module CLI
    class CLI < Thor

      desc "logout", "Clear juice credentials"
      def logout
        Blend::CLI::Juice.new.logout
      end

      desc "login", "Acquire juice credentials"
      def login
        Blend::CLI::Juice.new.login
      end

      desc 'projects', 'List of Juice projects'
      def projects
        Blend::CLI::Juice.new.projects
      end

      desc "hipchat COMMANDS", "Hipchat Control Module"
      subcommand "hipchat", Blend::CLI::Hipchat
      
      desc "github COMMANDS", "Github Control Module"
      subcommand "github", Blend::CLI::Github

      desc "juice COMMANDS", "Juice Control Module"
      subcommand "juice", Blend::CLI::Juice

      desc "heroku COMMANDS", "Heroku Control Module"
      subcommand "heroku", Blend::CLI::Heroku
    end
  end
end
