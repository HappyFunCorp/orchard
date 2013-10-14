module Orchard
  VERSION = "0.1.2a"

  class << self
    def version
      Orchard::VERSION.dup
    end 
  end 

end
