module Orchard
  module Status
    class Environment
      attr_accessor :project, :server, :environment

      def initialize( project, server, environment )
        @project = project
        @server = server
        @environment = environment
      end

      def check key, method
        ret = __send__( method )
        ret = false if ret.nil?
        ret = false if ret == []
        ret = ret.collect { |x| x[:name] || x['name'] }.join( "," ) if ret.is_a? Array

        pass = ret

        if( ret.is_a? Integer )
          if( method == :dyno_redundancy)
            pass = ret > 1
            ret = "#{ret} dynos"
          end
        end

        printf "%20s: ", key
        if( pass )
          printf "\u2713 #{ret}\n".encode('utf-8').green
        else
          printf "\u2718 #{ret}\n".encode('utf-8').red
        end
      end

      def client
        Orchard::Client.heroku_client
      end

      def log_monitoring
        client.addons(@server, /(logentries|keen|papertrail|loggly|flydata)/)
      end

      def app_monitoring
        client.addons(@server, /(relic)/)
      end

      def exception_handling
        client.addons(@server, /(airbrake|exceptional)/)
      end

      def deployhooks
        client.addons(@server, /deploynooks/)
      end

      def ssl
        client.addons(@server, /ssl/)
      end

      def backups
        client.backups(@server)
      end

      def database
        client.databases(@server)
      end

      def dyno_redundancy
        client.dynos(@server).to_i
      end

      def stack
        client.stack( @server ) == 'cedar'
      end

      def domains
        client.nonheroku_domains( @server )
      end
    end
  end
end
__END__





      desc 'check_domains [APP]', 'Check domains'
      def check_domains(app)
        client.nonheroku_domains(app).each do |domain|
          puts "\nChecking domain #{domain}:".blue
          result = DomainChecker.check(domain)

          if result.include? :error
            puts result[:error].red
            return
          end
          
          # Check registration
          if result[:registered]
            r = result[:registrar]

            # Registrar:
            if r.nil?
              printf "%25s: %s", 'Registrar', format_result(:warn, "DNS not configured correctly for #{domain}")
            else
              registrar = [r['name'], r['organization'], r['url']].reject(&:nil?).join(';  ')
              printf "%25s: %s", 'Registrar', format_result(:pass, registrar)
            end
          else
            printf "%25s: %s", 'Registrar', format_result(:fail)
          end


          unless result[:expires].nil?
            # Expiration:
            days_to_expiration = ((result[:expires] - Time.now)/(3600.0*24.0)).to_i 
            formatted_dte = "#{result[:expires].strftime("%F")} (#{days_to_expiration} days from now)"
            if days_to_expiration < 30
              state = :fail
            elsif days_to_expiration < 30*3
              state = :warn
            else
              state = :pass
            end

            printf "%25s: %s", 'Expiration date', format_result(state, formatted_dte)
          end

          printf "%25s:\n", 'DNS'
          result[:dns].each do |k,v|
            v[:domains].each do |record|
              if record[:type] == 'MX'
                description = "#{record[:data][0]}: #{record[:data][1].to_s}"
              else
                description = record[:data].to_s
              end
              printf "%25s  ", ''
              printf "%5s".green, record[:type].to_s
              printf "( ttl=%i ): %s\n", record[:ttl], description
            end
          end

        end
      end


    end
  end
end