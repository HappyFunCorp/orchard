module Orchard
  module Exceptions
    class AuthenticationFailure < StandardError; end
    class LoginAuthenticationFailure < StandardError; end
    class AlreadyLoggedIn < StandardError; end
    class AlreadyLoggedOut < StandardError; end
  end
end
