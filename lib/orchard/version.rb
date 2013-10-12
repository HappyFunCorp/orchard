module Orchard
  VERSION = "0.1.1a"

  class << self
    def version
      Orchard::VERSION.dup
    end 
  end 

end
