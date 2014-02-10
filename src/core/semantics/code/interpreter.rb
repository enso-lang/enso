#=begin
#
# Some definitions for documentation below:
# - operation: an action the interpreter can take, eg eval, debug, lvalue, etc
# - type: schema type, eg BinaryOp
# - method: name of method for {o:operation X t:type} eg eval_BinaryOp()
#=end

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
      if @current.has_key? field
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

    def debug
      @debug = true
      @indent = 0 if !@indent
    end
    
    def dynamic_bind fields={}, &block
      if !@D
        @D = DynamicPropertyStack.new
      end
      fields.each do |key, value|
        puts "BIND #{key}=#{value}" if @debug
        @D._bind(key, value)
      end
      result = block.call
      @D._pop(fields.size)
      result
    end

    def wrap(operation, outer, obj)
      type = obj.schema_class
      method = "#{outer}_#{type.name}".to_s
      if !respond_to?(method)
        method = find(outer, type)  # slow path
      end
      if !method
        method = "#{outer}_?".to_s
        if !respond_to?(method)
          raise "Missing method in interpreter for #{outer}_#{type.name}(#{obj})"
        end
      end
      send(method, obj) {
        dispatch_obj(operation, obj)
      }
    end

    def dispatch_obj(operation, obj)
      type = obj.schema_class
      method = "#{operation}_#{type.name}".to_s
      if !respond_to?(method)
        method = find(operation, type)  # slow path
      end
      if !method
        method = "#{operation}_?".to_s
        if !respond_to?(method)
          raise "Missing method in interpreter for #{operation}_#{type.name}(#{obj})"
        end
      end
      if @debug
        $stderr << "#{' '.repeat(@indent)}>#{operation} #{obj}\n"
        @indent = @indent + 1
      end
      result = send(method, obj)
      if @debug
        @indent = @indent - 1
        $stderr << "#{' '.repeat(@indent)}= #{result}\n"
      end
      result
    end

    def find(operation, type)
      method = "#{operation}_#{type.name}".to_s
      if respond_to?(method)
        method
      else
        type.supers.find_first do |p| 
          find(operation, p)
        end
      end
    end
  end
end
