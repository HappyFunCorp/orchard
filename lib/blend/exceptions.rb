module Blend
  module Exceptions
    class AuthenticationFailure < StandardError; end
    class LoginAuthenticationFailure < StandardError; end
    class AlreadyLoggedIn < StandardError; end
    class AlreadyLoggedOut < StandardError; end
    class HipchatAuthenticationFailure < StandardError; end

    class << self
      def formatted(e)
        puts "#{e.backtrace.shift}: #{e.message}"
        puts e.backtrace.first(10).map{|x| "\t"+x}.join("\n")
      end
    end
  end
end
