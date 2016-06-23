
module Bla
  class Foo
    @@id = 3
    include X
    include Y
      
    def initialize
      @@id += 1
    end
    
  end
end