require 'highline/import'

module Orchard
  module Client
    class HerokuClient

      attr_accessor :client
      
      def initialize( client )
        @client = client
        @addons = {}
      end
        
      def info( app )
        client.get_app(app).body
      end

      def domains( app ) 
        client.get_domains(app).body
      end

      def nonheroku_domains( app )
        domains(app).reject{|x| x['base_domain']=="herokuapp.com" || x['domain'] =~ /^www/}.collect{|x| x['domain']}
      end

      def addons( app, filter=nil )
        @addons[app] ||= client.get_addons(app).body
        if filter.nil?
          @addons[app]
        else
          @addons[app].select{|x| x['name'] =~ filter}
        end
      end

      def addon_names( app, filter )
        addons(app, filter).collect do |addon|
         name,plan = addon['name'].split(/:/)
         {name: name, plan: plan}
        end
      end

      def addon_matches( app, addon_name )
        addons(app).select{|x| x[:name] =~ addon_name}
      end

      def stack(app)
        info(app)['stack']
      end

      def dynos( app )
        info(app)['dynos']
      end

      def backups( app )
        addon_names(app, /pgbackups/)
      end

      def databases( app )
        addon_names(app, /postgresq/)
      end

      def run_domain_checker( app )
        results = {}
        nonheroku_domains(app).map{|x| x['domain']}.each do |d|


          DomainChecker.check(d)

          result = {}
          results[d] = result

          # Check registered
          result[:registered] = dc.registered?

          # Check registrar
          result[:registrar] = dc.registrar

          result[:ssl] = dc.ssl
        end

        results

      end

    end
  end
end
