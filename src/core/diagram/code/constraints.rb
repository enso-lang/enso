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
    @vars
    @value = val
    @bounds = []
  end

  def to_i
    return value.to_i
  end
  
  def to_s
    return value.to_s
  end
  
  def to_str
    return value.to_str
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

  def method_missing(m, *args)
    raise "undefiend method #{m}" unless [:+, :-, :*, :/, :round].include? m 
    var = Variable.new("p#{self.to_s}#{args.to_s}")
    #puts "#{var}=#{self.to_s}+#{args}"
    var.internal_define(self, *args) do |a, *other|
      a.send(m, *other)
    end
    return var
  end

  def internal_define(*vars, &block)
    raise "nil definition" if vars.any?(&:nil?)
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
        val = var.is_a?(Variable) ? var.internal_evaluate(path) : var
        if val.nil?
          puts "WARNING: undefined variable '#{var}'"
          val = 10
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
    #puts "CLEAR #{self.to_s}"
    @value = nil
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
  
