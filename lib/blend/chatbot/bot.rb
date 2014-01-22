require 'active_support/time'
require 'json'
require 'httparty'

module Blend
  class Bot < Lita::Handler
    route /^echo\s+(.+)/, :echo, command: true, help: { "echo test" => "Replies back with test" }
    route /^(wtf|what)\s*(happened )?([\w\s]*)\??$/i, :wtf, command: true, help: { "wtf [time interval]" => "Project activity. Time interval defaults to this week. Options are 'today', 'yesterday', 'this week', 'last week', 'this month', 'last month'.  'wtf happened' and 'what happened' are also valid." }
    route /^project_id/i, :project_id, command: true, help: { 'project_id' => 'Print the juice project id' }
    route /^projects/, :projects, command: true, help: {'projects' => 'A list of Juice projects'}
    route /^who\s+is\s+(\w+)\??/i, :whois, command: true, help: {'who is [SEARCH TERM]' => 'Search the rosetta stone for employee info'}

    route /^check$/, :check, command: true #totally incomplete and useless right now.
    route /^tell (\w+)\s*(he|to)?\s+(.*)/i, :tell, command: true
    route /^chuck$/, :chuck, command: true
    route /^make me a sandwich/, :make_me_a_sandwich, command: true
    route /^sudo make me a sandwich/, :sudo_make_me_a_sandwich, command: true
    route /^emoticons/, :emoticons, command: true, :help: {'emoticons' => 'List all emoticons'}

    def whois(response)
      answer = StringIO.new
      Client.juice_client.search_users( response.match_data[1] ).each_with_index do |user,i|
        answer.puts if i>0
        answer.puts "#{user['name'] || user['email']}:"
        %w( name country phone email personal_email skype_handle github_handle heroku_handle hipchat_handle).each do |field|
          answer.printf "%-15s: %s\n", field, (user[field].nil? || user[field].length==0 ? '?' : user[field])
        end
      end
      response.reply( answer.string )
    end


    class << self
      def project_id( response )
        Blend::Client.juice_client.project_id_from_room( ENV['HIPBOT_ROOM'] || response.message.source.room )
      end

      def capture_stderr
        previous_stderr, $stderr = $stderr, StringIO.new
        yield
        $stderr.string
      ensure
        $stderr = previous_stderr
      end

    end


    def tell(response)
      response.reply( "Hey #{response.match_data[1]}, #{response.match_data[3]}" )
    end
      



    def project_id(response)
      project_id = self.class.project_id(response)
      response.reply( 'No project found for this room!' ) and return if project_id.nil?

      response.reply( project_id )
    end


    def check(response)
      project_id = self.class.project_id(response)
      response.reply( 'No project found for this room!' ) and return if project_id.nil?

      response.reply( Client.juice_client.check( project_id ).to_s)
    end


    
    def wtf(response)

      case response.match_data[-1].strip
        when 'last month', 'lastmonth', 'last_month'
          after = (Time.now-1.month).beginning_of_month
          before = (Time.now-1.month).end_of_month
        when 'this month', 'thismonth', 'this_month'
          after = (Time.now).beginning_of_month
          before = (Time.now).end_of_month

        when 'last week', 'lastweek', 'last_week'
          after = (Time.now-1.week).beginning_of_week
          before = (Time.now-1.week).end_of_week
        when 'this week', 'thisweek', 'this_week'
          after = (Time.now).beginning_of_week
          before = (Time.now).end_of_week

        when 'today'
          after = (Time.now).beginning_of_day
          before = (Time.now).end_of_day
        when 'yesterday'
          after = (Time.now-1.day).beginning_of_day
          before = (Time.now-1.day).end_of_day
        else
          if response.match_data[-1].nil? or response.match_data[-1].length==0
            after = (Time.now).beginning_of_week
            before = (Time.now).end_of_week
          else
            response.reply("Unrecognized time interval, '#{response.match_data[-1]}'. Valid options are today, yesterday, this week, last week, this month, last month.")
            return
          end
      end

      
      project_id = self.class.project_id(response)
      response.reply( 'No project found for this room!' ) and return if project_id.nil?

      summary = Client.juice_client.activities( project_id, after, before)
      
      answer = StringIO.new

      answer.printf "Project activity from #{after.strftime('%A, %F')} to #{before.strftime('%A, %F')}\n"

      summary[:actors_activites].keys.sort.each do |x|
        summary[:actors_activites][x].keys.reject(&:nil?).sort.each do |type|
          answer.printf "%-6s %-25s %s\n", summary[:actors_activites][x][type].count, type.strip_email, x
        end
      end

      answer.puts

      #summary[:type].keys.sort.each do |x| 
        #answer.printf( "%-6s %s\n", summary[:type][x].count, x )
      #end 

      response.reply(answer.string)
    end

  
    def projects(response)
      answer = Blend::Client.juice_client.projects
      response.reply( answer.collect{|x| x['name']}.join(', ') )
    end


    def chuck(response)
      response.reply HTTParty.get('http://api.icndb.com/jokes/random').parsed_response['value']['joke']
    end

    def make_me_a_sandwich(response)
      response.reply('What? No. Make it yourself.')
    end

    def emoticons(response)
      response.reply(DATA)
    end

    def sudo_make_me_a_sandwich(response)
      response.reply('Okay.')
    end


    def echo(response)
      pp response.message.source
      domain = response.match_data[1]
      puts "Printing back #{domain}"
      # line = ::Cocaine::CommandLine.new("whois", ':domain')
      response.reply(domain)
    end

  end

  Lita.register_handler(Bot)
end


__END__
(allthethings)
(android)
(areyoukiddingme)
(arrington)
(ashton)
(atlassian)
(awthanks)
(awyeah)
(badass)
(badjokeeel)
(badpokerface)
(basket)
(beer)
(bitbucket)
(boom)
(branch)
(bumble)
(bunny)
(cadbury)
(cake)
(candycorn)
(caruso)
(ceilingcat)
(cereal)
(cerealspit)
(challengeaccepted)
(chewie)
(chocobunny)
(chompy)
(chris)
(chucknorris)
(clarence)
(coffee)
(confluence)
(content)
(continue)
(cornelius)
(dance)
(dealwithit)
(derp)
(disapproval)
(dosequis)
(drevil)
(ducreux)
(dumb)
(embarrassed)
(facepalm)
(failed)
(fap)
(firstworldproblem)
(fonzie)
(foreveralone)
(freddie)
(fry)
(fuckyeah)
(fwp)
(gangnamstyle)
(garret)
(gates)
(ghost)
(goodnews)
(greenbeer)
(grumpycat)
(gtfo)
(haveaseat)
(heart)
(hipchat)
(hipster)
(huh)
(ilied)
(indeed)
(iseewhatyoudidthere)
(itsatrap)
(jackie)
(jira)
(jobs)
(kennypowers)
(krang)
(kwanzaa)
(lincoln)
(lol)
(lolwut)
(megusta)
(menorah)
(mindblown)
(ninja)
(notbad)
(nothingtodohere)
(notsureif)
(notsureifgusta)
(obama)
(ohcrap)
(ohgodwhy)
(okay)
(omg)
(oops)
(orly)
(pbr)
(pete)
(philosoraptor)
(pingpong)
(pirate)
(pokerface)
(poo)
(present)
(pumpkin)
(rageguy)
(rebeccablack)
(reddit)
(romney)
(rudolph)
(sadpanda)
(sadtroll)
(samuel)
(santa)
(scumbag)
(seomoz)
(shamrock)
(shrug)
(skyrim)
(stare)
(success)
(successful)
(sweetjesus)
(tableflip)
(taft)
(tea)
(thumbsdown)
(thumbsup)
(tree)
(troll)
(truestory)
(trump)
(turkey)
(twss)
(unknown)
(washington)
(wat)
(wtf)
(yey)
(yodawg)
(yougotitdude)
(yuno)
(zoidberg)
(zzz)
8)
:#
:$
:'(
:')
:(
:)
:-*
:D
:Z
:\
:o
:p
:|
;)
;p
>:-(
O:)
(rock)
(will)
(whatdoesthatevenmean)
(fairenough)
(thatsawesome)
(doyouwanttochatnow)
(angryasian)
(racist)
(lacist)
(samsung)
(canweusejira)
(thatamazing)
(thatsamazeballs)
(chatnow)
(amazeballs)
(ricky)
(lumbergh)
(lumberg)
(sick)
(aaron)
