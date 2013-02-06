=begin
 Usage example: Interpreter(Debug.wrap(EvalExpr)).eval(exp1, env: {x: 5})

 Some definitions for documentation below:
 - operation: an action the interpreter can take, eg eval, debug, lvalue, etc
 - type: schema type, eg BinaryOp
 - visit method: action for {o:operation X t:type} eg eval_BinaryOp()
 - strategy: a visitor contain a set of visit methods plus interpreter configurations, eg EvalExpr
 - combinator: combines strategies to form new strategies, eg Wrap :: Strategy X Strategy -> Strategy
 - higher-order strategy: a strategy that is typically used with a combinator, eg Debug, Memo, AttrGrammar 
 - interpreter: initialized with strategy. can then use its operations on objects
 - interp: delayed execution of a strategy on an object, used by interpreter for composition and specialization
=end

require 'core/system/library/schema'

=begin
Base interpreter container for all interp objects created during an evaluation
This is the main interpreter interacting with the user
Each interpreter is created by accepting a set of strategies
Attributes:
  interpreter-level configuration info: eg @mods
  global interpreter state: @all_interps, @argstack
  State that is specific to one interpreter strategy do NOT go here
Methods:
  interpreter management methods: push/pop stack, get_interp, etc
  Each operation will get a method here
    - this method will invoke the first interpreter object
    - as well as contain hooks for init, cleanup, and default_args
=end 
class Interpreter
  def initialize(*mods)
    @all_interps = {}    #Note that this is a generic hashtable, so keys may be anything from 
                         # MObjects to Lists & Sets to even primitives
    @argstack = [{}]  #keep track of arguments passed to each call in the stack
                      #this is to allow visit methods to not pass arguments manually if they are unchanged
    @mods = mods
    method_syms = mods.map{|m|m.operations}.flatten.uniq #2nd uniq because two mods can def same method
    method_syms.each do |method_sym|
      define_singleton_method(method_sym) do |obj, args={}|
        int = get_interp(obj)
        int.send(:__init)
        res = int.send(method_sym, int.send(:__default_args)+args)
        int.send(:__cleanup)
        res
      end
    end
  end
  
  def get_interp(obj, field=nil)
    if @all_interps.has_key? obj
      @all_interps[obj] 
    else
      @all_interps[obj] = make_interp(obj, field)
    end
  end
  
  def make_interp(obj, field=nil)
    if obj.nil?
      nil 
    elsif field.nil?
      Interp.new(obj, self, @mods)
    elsif !field.many
      if field.type.Primitive?
        obj
      else
        Interp.new(obj, self, @mods)
      end
    else
      if Schema::is_keyed?(field.type)
        newl = {}
        obj.each {|val| newl[Schema::object_key(val)] = make_interp(val)}
      else
        newl = [] 
        obj.each {|val| newl << make_interp(val)}
      end
      newl
    end
  end
  
  def lastargs; @argstack.last end
  def pushargs(args); @argstack << args end 
  def popargs; @argstack.pop end
end

=begin
Interp represents a delayed execution of a strategy on an object
Essentially an interpreter specialized for this one object
An interpreter contains a graph of interps which it will invoke accordingly
Visit methods in strategies are passed interps, not the actual object
Attributes:
  @this is the object specialized for, 
  @interpreter is the containing interpreter
  Persistent state specific to an evaluation strategy go here, eg
    - State for only one interp: eg @memo
    - State globally applicable: eg @@sec_policy, @@workqueue
    - At this time impossible to share state between interp objects in different interpreters
Methods:
  Each operation, foo, will have the following methods:
    - foo: this is the usual method to call, normally it simply redirects to foo!
           (PS. this is needed because foo! is only created when the interpreter is specialized,
            but some combinators, eg Wrap, Rename, require a 'main' method to work with when the
            strategy is being defined, before the interpreter is used.
            So foo is that 'main' method that can be extended, renamed, etc before foo!
            is created)
    - foo!: invoke operation foo (on this object)
             specialized to the object --- any optimization/peval should be put here! 
             handles dispatch, argument mangling, error-handling, call stack mgmt, etc
             normally it calls some variant of foo_Type
    - foo_<Type>: these are visit methods included from strategies
    Try to define as few methods here as possible to avoid name clashes with operations!
  __bar: methods used by the interpreter machinery, eg __init, __cleanup
         to be overridden by strategies to produce specific behavior
  _bar: methods used by interpreter strategies (like Debug, Memo), eg _add_to_workqueue
  bar: methods used by user strategies (like eval, construct), eg closure
       utility methods in user strategies can clash with operations as well, so avoid them!
=end
class Interp
  #TODO: Undef some methods here, but make sure not to undef the later defined ones
  #ie DON'T use "undef"
  #begin; undef_method :lambda, :methods; rescue; end

  def initialize(obj, interpreter, mods=[])
    @this=obj
    @interpreter=interpreter

    mods.each {|mod| instance_eval {extend(mod)}}
    method_syms = mods.map{|m|m.operations}.flatten.uniq #2nd uniq because two mods can def same method
    method_syms.each do |method_sym|

      m = Schema::lookup(@this.schema_class) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
      if !m.nil?
        all_fields = @this.schema_class.all_fields

        define_singleton_method("#{method_sym}!") do |args={}, &block|
          __call(m, args) do |nargs|
            params = m.parameters.map do |k,v|
              name=v.to_s
              if all_fields.has_key? name
                @interpreter.get_interp(@this[name], all_fields[name])
              else
                nargs[v]
              end
            end
            m.call(*params, &block)
          end
        end
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym) 
        all_fields = @this.schema_class.all_fields

        define_singleton_method("#{method_sym}!") do |args={}, &block|
          __call(m, args) do |nargs|
            fields = Hash.new
            all_fields.each do |f|
              fields[f.name] = @interpreter.get_interp(@this[f.name], f)
            end
            m.call(@this.schema_class, fields, nargs, &block)
          end
        end
      else
        #$stderr << "Cannot find method #{method_sym} for #{@this}\n"
        #define_singleton_method(method_sym) do |*args| #this is necessary because method_missing is not 
                                                       #called for methods inherited from Object, eg 'eval'  
        #  self[method_sym]
        #end
      end
    end
    __setup
  end
  
  def method_missing(method_sym, *args)
    if @this.schema_class.fields.map{|f|f.name}.include?(method_sym.to_s)
      self[method_sym]
    else 
      super
    end
  end

  def [](key=nil)
    if key.nil?
      @this
    elsif field = @this.schema_class.fields[key.to_s]
      @interpreter.get_interp(@this[key.to_s], field)
    end
  end
  
  #to be overridden by interpreters
  def __init; end     #interpreter level initialization (after __setup of root interp)
  def __cleanup; end
  def __setup; end    #object level initialization (after modules loaded)
  def __hidden_calls; []; end
  def __default_args; {}; end

  #misc 
  def to_s; "Interp(#{@this})"; end
  def to_ary; end

  #private

  #utility call method that does miscellaneous wiring
  # -error handling
  # -default arguments
  # DO NOT OVERRIDE!!!
  def __call(m, args)
    args1 = @interpreter.lastargs+args
    @interpreter.pushargs(args1)
    begin
      yield args1
    rescue Exception => e
      unless __hidden_calls.include? m.name 
        $stderr<< "\tin #{@this}.#{m.name}(#{args})\n"
      end
      raise e
    ensure
      @interpreter.popargs
    end
  end
end

def Interpreter(*mods)
  Interpreter.new(*mods)
end

# easier to work with standard Ruby classes
class Hash
  def set!(key)
    self[key] = yield self[key]
  end
  def set(key, &block)
    res = self.clone
    res.set!(key, &block)
    res
  end
  def +(hash)
    merge(hash)
  end
end

class Array
  def values; self; end
end

class Module
  def operation(*ops)
    @operations||=[]
    @operations+=ops
    ops.each do |op|
      eval("
      define_method(:#{op}) do |args={}, &block|
        #{op}! args, &block
      end")
    end
  end

  def operations
    @operations||=[]
    (@operations + included_modules.map{|mod|mod.operations||[]}.flatten).uniq
  end
  def op_methods
    instance_methods.select{|m|operations.detect{|op|m.to_s.start_with? "#{op}_"}}
  end
end
