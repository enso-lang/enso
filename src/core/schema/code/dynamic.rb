

module ManagedData
  class DynamicUpdateProxy
    def initialize(obj)
      @obj = obj
      @fields = {}
    end
    
    def [](name)
      puts "DYNAMIC #{@obj}.#{name}"
      var = @fields[name]
      return var if var
      if !name.is_a?(Variable) && name.start_with?("_")
        return @obj.send(name.to_sym)
      end
      field = @obj.schema_class.all_fields[name]
      if field.many
        return @obj[name]
      elsif field.computed
        foo = @obj
        exp = field.computed.gsub(/@/, "foo.")
        if exp.start_with?("foo.")
          exp[0..3] = "self."
        end
        puts "Dynamic #{@obj}: #{exp}"
        return instance_eval(exp)
      else
        val = @obj[name]
      end
      val = val.dynamic_update if val.is_a?(ManagedData::MObject)
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

    def to_s
      "[#{@obj.to_s}]"
    end

    def dynamic_update; self end
    def schema_class; @obj.schema_class end
  end    
end
