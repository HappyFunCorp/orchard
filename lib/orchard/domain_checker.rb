require 'dnsruby'
require 'whois'
require 'httpclient'

class DomainChecker
  attr_accessor :domain, :res

  class << self
    def check(domain)
      dc = self.new(domain)

      result = {}
      begin

        result[:registered] = dc.registered?
        result[:registrar] = dc.registrar
        result[:ssl] = dc.ssl
        result[:expires] = dc.expires
        result[:owner] = dc.owner
        result[:name_servers] = dc.name_servers
        result[:dns] = {
          ns: dc.ns,
          mx: dc.mx,
          cname: dc.cname,
          a: dc.a
        }

      rescue Dnsruby::ServFail => e
        result[:error] = "DomainChecker encountered #{e.to_s}: You might just need to retry this."
      end

      result
    end
  end
  
  def initialize( domain )
    @domain = domain
    @res = Dnsruby::Resolver.new
  end

  ## Find out meta data

  def registered?
    whois.registered?
  end

  def registrar
    whois.registrar
  end

  def owner
    whois.registrant_contacts
  end

  def expires
    whois.expires_on
  end

  def inbound_mailers
    get_data(mx).sort { |a,b| a[0] <=> b[0]}
  end

  def name_servers
    get_data(ns)
  end

  def ssl
    if @ssl.nil?
      c = HTTPClient.new
      c.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      p = c.get( "https://#{domain}")
      @ssl = p.peer_cert
    end
    @ssl
  end

  ## Details

  def lookup( type )
    @results ||= {}
    if @results[type].nil?
      @results[type] = parse_answer( type )
      if type == "A" || type == "CNAME"
        @results[type] = parse_answer type, @results[type][:domains]
      end
    end

    # @results[type]
    #   @results = { domain: @domain }
    #   @results[:ns] = parse_answer( "NS" )
    #   @results[:a] = parse_answer( "A" )
    #   @results[:a] = parse_answer( "A", @results[:a][:domains] )
    #   @results[:cname] = parse_answer( "CNAME" )
    #   @results[:cname] = parse_answer( "CNAME", @results[:cname][:domains] )
    #   @results[:mx] = parse_answer( "MX" )
    # end
    @results[type]
  end
  
  def ns
    lookup "NS"
  end
  
  def a
    lookup "A"
  end
  
  def mx
    lookup "MX"
  end
  
  def cname
    lookup "CNAME"
  end
  
  def whois
    @whois ||= Whois.query @domain
  end

  def parse_answer( type, domains = false )
    domain = @domain
    domain = "www.#{@domain}" if domains
    ret = {domains: []}
    ret = {domains: domains} if domains
    begin
      rr = @res.query( domain, type)
      # puts rr.answer
      rr.answer.each do |answer|
        ret[:domains] << { domain: domain, name:answer.name.to_s, ttl: answer.ttl, data: answer.rdata, type: answer.type } if answer.type == type
      end
    rescue Dnsruby::ResolvTimeout
      ret[:error] = :timeout
    rescue Dnsruby::NXDomain
      ret[:error] = :notfound
    end
    
    ret
  end

  def get_data array
    array[:domains].collect{ |x| x[:data] }
  end
  
  # def registrar
  #   last_2_records ns
  # end
  
  # def mailer
  #   records( mx ).collect { |x| x[1].labels[-2..-1].collect { |x| x.to_s.downcase }.join( "." ) }.uniq.select { |x| x != "google.com"}
  # end
  
  # def last_2_records a
  #   records( a ).collect { |x| x.labels[-2..-1].collect { |x| x.to_s }.join( "." ) }.uniq
  # end
  
  # def records v
  #   if v[:domains]
  #     v[:domains].collect { |x| x[:data] }
  #   else
  #     []
  #   end
  # end
  
  def heroku?
    a_ips = a[:domains].select { |x| x[:domain] == @domain }.collect { |x| x[:data].to_s }.sort
    # puts a_ips
    return true if a_ips == ["174.129.212.2", "75.101.145.87", "75.101.163.44"] 
    

    # puts cname[:domains].to_s 
    # return false if cname[:domains].first[:data].to_s != "proxy.heroku.com"
    
    return true
  end
end

if __FILE__ == $0
  puts "Hi there"
  domains = DATA.readlines

  require 'pp'
  
  domains.each do |d|
    ret = DomainChecker.new( d.chomp )
    
    #printf( "%40s %15s %30s %30s\n", ret.domain, ret.heroku? ? "Heroku" : "Other", ret.mailer, ret.registrar)
    printf( "%40s %15s %50s %10i ms\n", ret.domain, ret.heroku? ? "Heroku" : "Other", (ret.registrar.name rescue nil), ret.ping)
    # pp ret
  end
end

__END__
benchcoach.com
bittersoft.com
coldipozzo.com
DEREKFLANZRAICH.COM
friendopp.com
FriendsofFriend.com
greatist.com
happyfuncook.com
happyfuncorp.com
happyfungo.com
ianmacrae.com
knowhub.com
lithosdumonde.com
methodeducation.com
pregosophy.com
sangparkllc.com
scooprank.com
setlr.com
sublimeguile.com
thecgcgroup.com
thesleepwell.org
tripodpix.com
twoseed.com
unmarriedhousewife.com
verisignmobileviewhrchallenge.com
veryrobinreed.com
veteransyogaproject.com
veteransyogaproject.org
allegorylaw.com
barnacle.is
doudeal.com
friendopp.com
happyfungo.com
happyfunrun.com
happyfuncorp.com
knowhub.com
methodeducation.com
listenfirstmedia.com
qplay.me
rateyourburn.com
setlr.com
waffleme.com
wyst.it
yeahtvstaff.com
