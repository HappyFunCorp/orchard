module Orchard
  module CLI
    class Juice < Thor
      desc "login", "Login to juice"
      def login
      end

      desc "open", "Open up juice"
      def open
        system "open http://happyfunjuice.com"
      end

      desc "projects", "List juice projects"
      def projects
        client.projects.each do |project|
          require 'pp'
          pp project
        end
      end

      desc "project ID", "Get project meta data"
      def project( id )
      end

      desc "lookup_user EMAIL", "Looks up a user by email address"
      def lookup_user( email )
      end

      no_commands do
        def client
          @client ||= Orchard::Client.juice_client
        end
      end
    end
  end
end