class TrueClass
  def test(a, b)
    #puts "TRUE TEST VARIABLE!!! #{a} else #{b}"
    return a
  end
end
class FalseClass
  def test(a, b)
    #puts "FALSE TEST VARIABLE!!! #{a} else #{b}"
    return b
  end
end

class ConstraintSystem
  def initialize
    @vars = {}
    @number = 0
  end
  
  def var(name = "v#{@number}", value = nil)
    @number += 1
    #puts "#{name} = #{value}"
    return Variable.new(name, value)
  end
  
  def value(n)
    var("(#{n})", n)
  end
  
  def [](name)
    var = @vars[name]  
    var = @vars[name] = self.var if !var
    return var
  end
end

class Variable
  def initialize(name, val = nil)
    @name = name
    @dependencies = []
    @vars = []
    @value = val
    @bounds = []
    throw "NO name variable" if name.to_s == ""
  end

  def to_i
    return value.to_i
  end
  
  def to_s
    return value.to_s
  end
  
  def to_str
    return value.to_s
  end

  def inspect
    return "<VAR #{@name}=#{@val}>"
  end

  def to_ary
    return [self]
  end
    
  def is_a?(kind)
    return true if kind == Variable
    return value.is_a?(kind)
  end
 
  # special case for >= to implement MAX behavior
  def >=(other)
    #puts "#{self} >= #{other}"
    other.add_listener(self) if other.is_a?(Variable)
    @bounds << other
  end

  def test(a, b)
    var = Variable.new("test#{self.to_s}")
    var.internal_define("test", self, a, b) do |v, ra, rb|
      #puts "EVALUATING TEST VARIABLE!!! #{a} else #{b}"
      v.test(ra, rb)
    end
    var
  end
  
  def method_missing(m, *args)
    if value && (value.is_a?(Factory::MObject) || value.is_a?(Factory::DynamicUpdateProxy))
      if m.to_s =~  /^[^=]*=$/
        return value.send(m, *args)
      elsif args==[]
        return value.dynamic_update.send(m, *args)
      end
    end
    raise "undefined method #{m} on VARIABLE #{value}" unless [:eql?, :+, :-, :*, :/, :round, :schema_class].include? m
    var = Variable.new("p#{self.to_s}#{args.to_s}")
    #puts "#{var}=#{self.to_s}+#{args}"
    var.internal_define(m, self, *args) do |a, *other|
      a.send(m, *other)
    end
    var
  end

  def new_var_method(&block)
    var = Variable.new("p#{self.to_s}")
    var.internal_define("new_var", self, &block)
    var
  end

  def eql?(x)
    method_missing(:eql?, x)
  end
  
  def internal_define(op, *vars, &block)
    raise "nil definition for '#{op}' on #{vars}" if vars.any?(&:nil?)
    @vars = vars
    @vars.each do |v|
      v.add_listener(self) if v.is_a?(Variable)
    end
    #puts "#{vars}"
    @block = block
  end
  
  def internal_evaluate(path = [])
    raise "circular constraint #{path.collect(&:to_s)}" if path.include?(self)
    if @block
      path << self
      vals = @vars.collect do |var|
        if var.is_a?(Variable)
          val = var.internal_evaluate(path)
          throw "unbound variable #{var.inspect}" if val.nil?
        else
          val = var
        end
        val
      end
      path.pop
      @value = @block.call(*vals)
    end
    @bounds.each do |b|
      val = if b.is_a?(Variable) then b.value else b end
      @value = val if !@value || @value < val
    end
    #puts "EVAL #{@name}=#{@value}"
    @value
  end
  
  def add_listener(x)
    #puts "#{x.to_s} listening to #{self.to_s}"
    @dependencies << x
  end

  def internal_notify_change
    @dependencies.each do |var|
      var.internal_notify_change
    end
    #@block.nil means this is a hardcoded var, probably because someone assigned to it
    @value = nil unless @block.nil?
  end
    
  def value
    internal_evaluate unless @value
    return @value
  end
  
  def value=(x)
    @block = nil
    internal_notify_change
    @value = x
  end
end
  
