require 'enso'

module Constraints

	class ConstraintSystem
	  def initialize
	    @vars = {}
	    @number = 0
	  end
	  
	  def variable(name = "v#{@number}", value = nil)
	    @number += 1
	    #puts "#{name} = #{value}"
	    Variable.new(name, value)
	  end
	  
	  def value(n)
	    variable("(#{n})", n)
	  end
	end
	
	class Constant
	  def initialize(val)
	    @value = val
	  end
	  
	  
	  def add_listener(l)
	  end
	  
	  def internal_evaluate(path)
	  	@value
	  end

	  def value
	  	@value
	  end
	
		def to_i
	    value.to_i
	  end
	  
	  def to_s
	    value.nil? ? "nil" : value.to_s
	  end
	  
	  def to_ary
	    [self]
	  end
	end
	
	class Variable < Constant
	  def initialize(name, val = nil)
	    super(val)
	    @name = name
	    @dependencies = []
	    @vars = []
	    @bounds = nil
	  end
		 
	  def add(other)
	    define_result(:add, other)
	  end
		      
	  def sub(other)
	    define_result(:sub, other)
	  end
		      
	  def mul(other)
	    define_result(:mul, other)
	  end
		      
	  def div(other)
	    define_result(:div, other)
	  end

	  def round
	    define_result(:round)
	  end
		      
	  def to_int
	    define_result(:to_int)
	  end
		      
	  # special case to implement MAX behavior
	  def max(other = raise("MAX WITH UNDEFINED"))
	    #puts "#{self} MAX #{other}"
	    other.add_listener(self) if other.is_a?(Variable)
	    @bounds = [] if @bounds.nil?
	    @bounds << other
	  end
	
	  def test(a, b)
	    variable = Variable.new("test#{self.to_s}")
	    variable.internal_define(self, a, b) do |v, ra, rb|
	      #puts "EVALUATING TEST VARIABLE!!! #{a} else #{b}"
	      v.test(ra, rb)
	    end
	    variable
	  end

	  def new_var_method(&block)
	    variable = Variable.new("p#{self.to_s}")
	    variable.internal_define(self, &block)
	    variable
	  end
	
	  def define_result(m, *args)
	    raise "undefined method #{m}" unless [:add, :sub, :mul, :div, :round, :to_int].include?(m) 
	    variable = Variable.new("p#{self.to_s}#{args.to_s}")
	    #puts "#{variable}=#{self.to_s}+#{args}"
	    variable.internal_define(self, *args) do |*values|
	      do_op(m, *values)
	    end
	    variable
	  end
	  
		def do_op(op, *values)
		  case op
		  when :add   
		  	values[0] + values[1]
		  when :sub
		  	values[0] - values[1]
		  when :mul
		  	values[0] * values[1]
		  when :div
		  	values[0] / values[1]
		  when :round
		  	values[0].round
		  when :to_int
		  	values[0].to_int
		  end
		end
	  
	  def internal_define(*vars, &block)
	    raise "DOUBLE defined Var" if @block
	    @vars = vars.map do |v|
	      if v.nil?
			    raise "Unbound variable #{v.toString}"
	      elsif v.is_a?(Constant) || v.is_a?(Variable)
	        v
	      else
	        Constant.new(v)
	      end
	    end
	    @vars.each do |v|
	      v.add_listener(self)
	    end
	    #puts "#{vars}"
	    @block = block
	  end
	  
	  def add_listener(x)
	    #puts "#{x.to_s} listening to #{self.to_s}"
	    @dependencies << x
	  end
	
	  def value
	    internal_evaluate unless @value
	    @value
	  end
	  
	  def value=(x)
	    @block = nil
	    internal_notify_change
	    @value = x
	  end

		def redo_max 
		  @value = nil
		  internal_notify_change
		end

	  def internal_notify_change
	    @dependencies.each do |variable|
	      variable.internal_notify_change
	    end
	    #@block.nil means this is a hardcoded var, probably because someone assigned to it
	    @value = nil unless @block.nil?
	  end
	    	  
	  def internal_evaluate(path = [])
	    raise "circular constraint #{path.map(&:to_s)}" if path.include?(self)
	    @value = nil if @bounds
	    if @block
	      path << self
	      vals = @vars.map do |variable|
	        val = variable.internal_evaluate(path)
	        if val.nil?
	          puts "WARNING: undefined variable '#{variable}'"
	          val = 10
	        end
	        val
	      end
	      path.pop
	      @value = @block.call(*vals)
	    end
	    if @bounds
		    @bounds.each do |b|
		      if b.is_a?(Variable) 
		        val = b.value
		      else
		        val = b
		      end
		      @value = val if @value.nil? || @value < val
		    end
		  end
	    #puts "EVAL #{@name}=#{@value}"
	    @value
	  end
	end
end