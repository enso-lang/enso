#=begin
#
# Some definitions for documentation below:
# - operation: an action the interpreter can take, eg eval, debug, lvalue, etc
# - type: schema type, eg BinaryOp
# - method: name of method for {o:operation X t:type} eg eval_BinaryOp()
#=end

require 'enso'

module Interpreter
  class DynamicPropertyStack
    def initialize
      @current = {}
      @stack = []
    end
    
    def [](name)
      @current[name]
    end

    def include?(name)
      @current.include?(name)
    end
    
    def keys
      @current.keys
    end
    
    def _bind(field, value)
      if @current.has_key?(field)
        old = @current[field]
      else
        old = :undefined
      end
      @stack << [field, old]
      @current[field] = value
    end
    
    def _pop(n = 1)
      while (n > 0) do
        parts = @stack.pop
        if parts[1] == :undefined
          @current.delete(parts[0])
        else
          @current[parts[0]] = parts[1]
        end
        n -= 1
      end
    end

    def to_s
      @current.to_s
    end
  end
  
  module Dispatcher
    def init
      if !@D
        @D = DynamicPropertyStack.new
      end
      @indent = nil
    end

    def dynamic_bind(fields={}, &block)
      if !@D
        @D = DynamicPropertyStack.new
      end
      fields.each do |key, value|
        @D._bind(key, value)
      end
      result = block.call
      @D._pop(fields.size)
      result
    end

    def wrap(operation, outer, obj)
      init_done = @init
      if !init_done
        init
      end
      @init = true
      type = obj.schema_class
      method = "#{outer}_#{type.name}".to_s
      if !respond_to?(method)
        method = find_op(outer, type)  # slow path
      end
      if !method
        method = "#{outer}_?".to_s
        if !respond_to?(method)
          raise "Missing method in interpreter for #{outer}_#{type.name}(#{obj})"
        end
      end
      result = nil
      send(method, obj) {
        result = dispatch_obj(operation, obj)
      }
      if !init_done
        @init = false
      end
      result
    end

    def dispatch_obj(operation, obj)
      init_done = @init
      if !init_done
        init
      end
      @init = true
      type = obj.schema_class
      method = "#{operation}_#{type.name}".to_s
      if !respond_to?(method)
        method = find_op(operation, type)  # slow path
      end
      if !method
        method = "#{operation}_?".to_s
        if !respond_to?(method)
          raise "Missing method in interpreter for #{operation}_#{type.name}(#{obj})"
        end
      end
      if @indent
      	STDERR.puts "#{' '*@indent}#{method}"
      	@indent = @indent + 1
     	end
      result = send(method, obj)
      if @indent
      	STDERR.puts "#{' '*@indent}=#{result}"
      	@indent = @indent - 1
     	end
      if !init_done
        @init = false
      end
      result
    end

    def find_op(operation, type)
      method = "#{operation}_#{type.name}".to_s
      if respond_to?(method)
        method
      else
        type.supers.find_first do |p| 
          find_op(operation, p)
        end
      end
    end
  end
end
