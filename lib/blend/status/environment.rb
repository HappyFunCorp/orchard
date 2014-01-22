module Blend
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
        ret = ret.collect do |x|
          if( x.is_a? Hash )
            x[:name] || x['name']
          else
            x
          end
        end.join( "," ) if ret.is_a? Array

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
          if( @project.resolve )
            r = "resolve_#{method}".to_sym
            __send__(r) if respond_to? r
          end

        end
      end

      def client
        Blend::Client.heroku_client
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
        client.addons(@server, /deployhooks/)
      end

      def resolve_deployhooks
        system( "echo heroku addons:add deployhooks:hipchat --auth_token=#{@project.juice_client.hipchat_api} --room=\"#{@project.config['hipchat_room']}\" --app #{@server}")
        system( "heroku addons:add deployhooks:hipchat --auth_token=#{@project.juice_client.hipchat_api} --room=\"#{@project.config['hipchat_room']}\" --app #{@server}" )
        Blend::Client::hipchat_client.post_message @project.config['hipchat_room'], "Heroku app: #{@server} commit hook now added"

      end

      def ssl
        client.addons(@server, /ssl/)
      end

      def backups
        client.backups(@server).collect { |x| x[:plan] }
      end

      def database
        client.databases(@server).collect { |x| x[:plan] }
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