
module WorkList
  # Maintains a worklist of nodes to work on
  # There is no guarantee that the same node will not be called multiple times
  #  and this behavior is sometimes needed (eg attribute grammars)

  attr_accessor :worklist

  def initialize(*args)
    @worklist = []
    super
  end

  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    args = arguments[1]

    @worklist << obj unless obj.nil? or @worklist.include?(obj)
    if !@working
      @working = true
      while !@worklist.empty?
        super(method_sym, @worklist.pop, args, &block)
      end
      @working = false
    end
  end
end

module Memoize
  # Ensures no node will be called more than once
  # If default is defined, memo of a current node will be set to default or default(node)
  #  depending on whether default is a proc
  #  otherwise it will be set to true
  #  this is to handle cyclic object graphs

  attr_accessor :memo, :default

  def initialize(*args)
    @memo = {}
    super
  end

  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    if !@memo[obj].nil?
      @memo[obj]
    else
      if @default.nil?
        @memo[obj] = true
      elsif @default.is_a? Proc
        @memo[obj] = @default.call(*arguments, &block)
      else
        @memo[obj] = @default
      end
      res = super
      @memo[obj] = res
    end
  end
end

module Propagate
  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    args = arguments[1]

    new = super(method_sym, obj, args, &block)
    obj.schema_class.fields.each do |f|
      if !f.type.Primitive?
        if !f.many
          send(method_sym, obj[f.name], args, &block) unless obj[f.name].nil?
        else
          obj[f.name].map{|o|send(method_sym, o, args, &block)}
        end
      end
    end
    new
  end
end

module Map
  include Propagate
  include Memoize
end


class InterpError < Exception
end

class Interpreter3
  module Dispatch
    def method_missing(method_sym, *arguments, &block)
    
      obj = arguments[0]
      raise "Interpreter: obj is nil for method #{method_sym}" if obj.nil?
      #raise "Interpreter: invalid obj #{obj} for method #{method_sym}" if !obj.is_a? ManagedData::MObject
      args = arguments[1]
      raise "Interpreter: args is not a hash in #{obj}.#{method_sym}" if args and !args.is_a? Hash

      args ||= {}
      args[:self] = obj

      af = obj.schema_class.all_fields
      fields = Hash[af.map{|f|[nil,nil]}]
      fields = Hash[af.map{|f|[f.name,obj[f.name]]}]

      __call(method_sym, fields, obj.schema_class, args)

    end

    private

    def __call(method_sym, fields, type, args)
      begin
        m = Lookup(type) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
        if !m.nil?

          params = []
          m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}.each do |f|
            params << fields[f]
          end

          m.call(*params, args)
  
        elsif respond_to?("#{method_sym}_?")
          m = method("#{method_sym}_?".to_sym)
          m.call(fields, type, args)

        else
          raise "Unable to resolve method #{method_sym} for #{type}"
        end
      rescue Exception => e 
        puts "\tin #{args[:self]}.#{method_sym}(#{args})"
        raise e
      end
    end
  end

  include Dispatch

  def compose!(*mods)
    mods.each {|mod| instance_eval {extend(mod)}}
    initialize
    self
  end
end

def Interpreter3(*mods)
  Interpreter3.new.compose!(*mods)
end
