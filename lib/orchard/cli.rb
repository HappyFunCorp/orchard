require 'orchard/cli/hipchat'
require 'orchard/cli/github'
require 'orchard/cli/juice'
require 'orchard/cli/heroku'

module Orchard
  module CLI
    class CLI < Thor

      desc "logout", "Clear juice credentials"
      def logout
        Orchard::CLI::Juice.new.logout
      end

      desc "login", "Acquire juice credentials"
      def login
        Orchard::CLI::Juice.new.login
      end

      desc 'projects', 'List of Juice projects'
      def projects
        Orchard::CLI::Juice.new.projects
      end

      desc "hipchat COMMANDS", "Hipchat Control Module"
      subcommand "hipchat", Orchard::CLI::Hipchat
      
      desc "github COMMANDS", "Github Control Module"
      subcommand "github", Orchard::CLI::Github

      desc "juice COMMANDS", "Juice Control Module"
      subcommand "juice", Orchard::CLI::Juice

      desc "heroku COMMANDS", "Heroku Control Module"
      subcommand "heroku", Orchard::CLI::Heroku
    end
  end
end
