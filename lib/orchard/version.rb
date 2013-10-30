module Orchard
  VERSION = "0.1.3a"

  class << self
    def version
      Orchard::VERSION.dup
    end 
  end 

end
