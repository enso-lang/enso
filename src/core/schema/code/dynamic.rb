
require "enso"

module Dynamic
  class DynamicUpdateProxy < Enso::EnsoProxyObject
    def initialize(obj)
      super()
      @obj = obj
      @fields = {}
      @obj.schema_class.fields.each do |fld|
        define_getter(fld.name, @obj.props[fld.name])
        define_setter(fld.name, @obj.props[fld.name])
      end
    end
    
    def get(name)
      #puts "DYNAMIC #{@obj}.#{name}"
      variable = @fields[name]
      if variable
        variable
      elsif !name.is_a?(Variable) && name.start_with?("_")
        @obj.send(name.to_sym)
      else
        field = @obj.schema_class.all_fields[name]
        if field.many
          @obj[name]
#       elsif field.computed
#         foo = @obj
#         exp = field.computed.gsub("@", "foo.")
#         if exp.start_with?("foo.")
#           exp[0..3] = "self."
#         end
#         puts "Dynamic #{@obj}: #{exp}"
#         return instance_eval(exp)
        else
          val = @obj[name]
          val = val.dynamic_update if val.is_a?(Factory::MObject)
          @fields[name] = variable = Variable.new("#{@obj}.#{name}", val)
          @obj.add_listener name do |val|
            variable.value = val
          end
          variable
        end
      end
    end
    
    def _set(name, val)
      @obj[name] = args[0]
    end
    
    def to_s
      "[#{@obj.to_s}]"
    end

    def dynamic_update; self end
    def schema_class; @obj.schema_class end
  end    
end
