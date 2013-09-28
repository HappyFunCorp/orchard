require 'orchard/cli/hipchat'
require 'orchard/cli/github'
require 'orchard/cli/juice'

module Orchard
  module CLI
    class CLI < Thor
      desc "hello NAME", "Says hello"
      def hello( name )
        puts "Hello #{name}!"
      end

      desc "hipchat COMMANDS", "Hipchat Control Module"
      subcommand "hipchat", Orchard::CLI::Hipchat
      
      desc "github COMMANDS", "Github Control Module"
      subcommand "github", Orchard::CLI::Github

      desc "juice COMMANDS", "Juice Control Module"
      subcommand "juice", Orchard::CLI::Juice
    end
  end
end