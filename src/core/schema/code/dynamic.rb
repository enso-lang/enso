

module ManagedData
  class DynamicUpdateProxy
    def initialize(obj)
      @obj = obj
      @fields = {}
    end
    
    def [](name)
      var = @fields[name]
      return var if var
      val = @obj[name]
      @fields[name] = var = Variable.new("#{@obj}.#{name}", val)
      @obj.add_listener name do |val|
        var.value = val
      end
      return var
    end
    
    def method_missing(m, *args)
      if m =~ /(.*)=/
        @obj[$1] = args[0]
      else
        return self[m.to_s]
      end
    end
  end
end
