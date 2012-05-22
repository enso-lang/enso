require 'core/expr/code/eval'

module LValueExpr
  include EvalExpr

  # An address class that simulates l-values (since Ruby does not have them)
  # Only two types of l-values are allowed: fields of schema objects and variables in the environment
  # coincidentally, both handled via the same syntax. Including other types may require subclassing
  class Address
    def initialize(array, index)
      @array = array
      @index = index
      unless @array.has_key? @index
        @array[@index] = nil
      end
    end

    attr_reader :array
    attr_reader :index

    def value=(val)
      if type
        case type.name
          when 'int'
            val = val.to_i
          when 'str'
            val = val.to_s
          when 'real'
            val = val.to_f
        end
      end
      begin; @array[@index] = val; rescue; end
    end

    def value
      @array[@index]
    end

    def to_str
      "#{@array}[#{@index}]"
    end

    def type
      @array.is_a?(ManagedData::MObject) ? @array.schema_class.all_fields[@index].type : nil
    end

    def object
      @array.is_a?(ManagedData::MObject) ? @array : nil
    end
  end

  def lvalue_EField(e, fname, args=nil)
    Address.new(ObjEnv.new(self.eval(e, args)), fname)
  end

  def lvalue_EVar(name, args=nil)
    Address.new(args[:env], name)
  end

  def lvalue_?(fields, type, args={})
    nil
  end
end
