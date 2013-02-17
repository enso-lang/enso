require 'core/expr/code/eval'
require 'core/semantics/code/interpreter'

module Lvalue
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
      @array.is_a?(Env::ObjEnv) ? @array.type(@index) : nil
    end

    def object
      @array.is_a?(Env::ObjEnv) ? @array.obj : nil
    end
  end

  module LValueExpr
    include Eval::EvalExpr
    
    include Interpreter::Dispatcher    
      
    def lvalue(obj)
      dispatch(:lvalue, obj)
    end
    
    def lvalue_EField(e, fname)
      Address.new(Env::ObjEnv.new(eval(e)), fname)
    end
  
    def lvalue_EVar(name)
      Address.new(@D[:env], name)
    end
  
    def lvalue_?(type, fields, args)
      nil
    end
  end
  
  class LValueExprC
    include LValueExpr
    def initialize
    end
  end
end