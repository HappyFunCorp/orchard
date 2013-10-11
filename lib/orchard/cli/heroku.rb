module Orchard
  module CLI
    class Heroku < Thor

      desc "info [APP]", "Prints info for a given app"
      def info( app )
        puts
        _info = client.info(app)
        _info.reject{|x| %w(domain_name).include? x}.each do |k,v|
          printf "%35s: %-25s\n", k, v
        end
        puts
      end

      desc 'domains [APP]', 'Print domain info'
      def domains(app)
        d = client.domains(app)
        d.each do |params|
          puts "\n#{params['domain']}:".blue
          params.each do |k,v|
            printf "%15s: %-25s\n", k, v
          end
        end
        puts
      end

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

      desc 'check_log_monitoring_addon [APP]', 'Check for log monitoring add-on'
      def check_log_monitoring_addon(app)
        a = client.addons(app, /(logentries|keen|papertrail|loggly|flydata)/)
        names = a.collect{|x| x['name']}.join(', ')
        result = a.count > 0 ? format_result(:pass, names) : result = format_result(:fail)
        printf "%25s: %s", 'Log monitoring add-on', result
      end

      desc 'check_app_monitoring_addon [APP]', 'Check for app monitoring add-on'
      def check_app_monitoring_addon(app)
        a = client.addons(app, /(relic)/)
        names = a.collect{|x| x['name']}.join(', ')
        result = a.count > 0 ? format_result(:pass, names) : result = format_result(:fail)
        printf "%25s: %s", 'App monitoring add-on', result
      end

      desc 'check_exception_handling_addon [APP]', 'Check for exception handling add-on'
      def check_exception_handling_addon(app)
        a = client.addons(app, /(airbrake|exceptional)/)
        names = a.collect{|x| x['name']}.join(', ')
        result = a.count > 0 ? format_result(:pass, names) : format_result(:fail)
        printf "%25s: %s", 'Exception handling add-on', result
      end


      desc 'check_ssl_addon [APP]', 'Check for SSL addon'
      def check_ssl_addon(app)
        a = client.addons(app, /ssl/)
        names = a.collect{|x| x['name']}.join(', ')
        result = a.count > 0 ? format_result(:pass, names) : format_result(:warn)
        printf "%25s: %s", 'SSL add-on', result
      end


      desc "addons [APP]", "Print addons for a given app"
      def addons(app)
        _addons = client.addons(app)
        _addons.each do |addon|
          puts addon['name']
        end
      end

      desc "addon_price [APP]", "Show the price of app addons"
      def addon_price(app)
        _addons = client.addons(app)
        _addons.each do |addon|
          printf "%-35s: $%10.2f / %-10s\n", addon['name'], addon['price']['cents'].to_i*0.01, addon['price']['unit']
        end
      end

      desc "check_backups [APP]", "Check to make sure the app is properly set up"
      def check_backups(app)
        printf "%25s: ", "Database backups"
        b = client.backups(app)
        if b.count==0
          printf format_result(:fail)
        else
          printf format_result(:pass, b.collect{|x| x[:plan]}.join(', '))
        end
      end

      desc 'check_database [APP]', 'Make sure we\'re running a production database'
      def check_database(app)
        printf "%25s: ", "Databases"
        b = client.databases(app)
        unique_plans = b.collect{|x| x[:plan]}.uniq
        if b.nil?
          printf format_result(:fail)
        elsif unique_plans.count==1 and unique_plans[0]=='dev'
          printf format_result(:warn, b.collect{|x| x[:plan]}.join(', '))
        else
          printf format_result(:pass, b.collect{|x| x[:plan]}.join(', '))
        end
      end

      desc 'check_dyno_redundancy [APP]', 'Make sure more than one dyno is assigned'
      def check_dyno_redundancy(app)
        printf "%25s: ", "Dyno redundancy"
        d = client.dynos(app).to_i
        if d > 1
          printf format_result(:pass, "#{d} dynos")
        else
          printf format_result(:fail, "#{d} dyno")
        end
      end

      desc 'check_stack [APP]', 'Make sure app is on cedar stack'
      def check_stack(app)
        printf "%25s: ", "Cedar stack"
        s = client.stack(app)
        if s == 'cedar'
          printf format_result(:pass, s)
        else
          printf format_result(:fail, s)
        end
      end
        

      desc 'check [APP]', 'Run production check for app'
      def check(app)
        puts
        puts "Checking app #{app}:".blue
        check_dyno_redundancy(app)
        check_database(app)
        check_backups(app)
        check_stack(app)
        check_exception_handling_addon(app)
        check_log_monitoring_addon(app)
        check_app_monitoring_addon(app)
        check_ssl_addon(app)
        check_domains(app)
        puts
      end

        





      no_commands do
        def client
          @client ||= Orchard::Client.heroku_client
        end
      end

      no_tasks do
        def format_result( state, message=nil )
          case state
            when :pass
              sprintf "\u2713 #{message}\n".encode('utf-8').green
            when :warn
              sprintf "\u2718 #{message}\n".encode('utf-8').yellow
            when :fail
              sprintf "\u2718 #{message}\n".encode('utf-8').red
          end
        end
      end

    end
  end
end
