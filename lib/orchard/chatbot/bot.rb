module Orchard
  class Bot < Lita::Handler
    route /^echo\s+(.+)/, :echo, command: true, help: { "echo test" => "Replies back with test" }

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
