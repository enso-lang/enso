=begin
Base interpreter container. Operations must be rolled in before it is used
=end

require 'core/system/library/schema'

class Interpreter
  def initialize(*mods)
    @all_interps = {}    #Note that this is a generic hashtable, so keys may be anything from 
                         # MObjects to Lists & Sets to even primitives
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
    return @all_interps[obj] if @all_interps.has_key? obj
    @all_interps[obj] = make_interp(obj, field)
  end
  
  def make_interp(obj, field=nil)
    return nil if obj.nil?
    return Interp.new(obj, self, @mods) if field.nil?
    if !field.many
      if field.type.Primitive?
        obj
      else
        Interp.new(obj, self, @mods)
      end
    else
      if IsKeyed?(field.type)
        newl = {}
        obj.each {|val| newl[ObjectKey(val)] = make_interp(val)}
      else
        newl = [] 
        obj.each {|val| newl << make_interp(val)}
      end
      newl
    end
  end
end

class Interp
  #TODO: Undef some methods here, but make sure not to undef the later defined ones
  #ie DON'T use "undef"
  #begin; undef_method :lambda, :methods; rescue; end

  def initialize(obj, interpreter, mods=[])
    @this=obj
    @interpreter=interpreter
    @mods=mods

    mods.each {|mod| instance_eval {extend(mod)}}
    method_syms = mods.map{|m|m.operations}.flatten.uniq #2nd uniq because two mods can def same method
    method_syms.each do |method_sym|
      m = Lookup(@this.schema_class) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
      if !m.nil?
        param_names = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

        define_singleton_method(method_sym) do |args={}, &block|
          params = param_names.map{|p|@interpreter.get_interp(@this[p], @this.schema_class.all_fields[p])}
          begin
            m.call(*params, args, &block)
          rescue Exception => e
            unless __hidden_calls.include? method_sym 
              $stderr<< "\tin #{@this}.#{method_sym}(#{args})\n"
            end
            raise e
          end
        end
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym) 
        param_names = @this.schema_class.all_fields.map{|f|f.name}

        define_singleton_method(method_sym) do |args={}, &block|
          params = Hash[*param_names.map{|p|[p, @interpreter.get_interp(@this[p], @this.schema_class.all_fields[p])]}.flatten(1)]
          begin
            m.call(@this.schema_class, params, args, &block)
          rescue Exception => e
            unless __hidden_calls.include? method_sym 
              $stderr<< "\tin #{@this}.#{method_sym}(#{args})\n"
            end
            raise e
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
  end
  
  def method_missing(method_sym, *args)
    if @this.schema_class.fields.map{|f|f.name}.include?(method_sym.to_s)
      self[method_sym]
    else 
      super
    end
  end
  
  def [](key=nil)
    return @this if key.nil?
    if field = @this.schema_class.fields[key.to_s]
      @interpreter.get_interp(@this[key.to_s], field)
    end
  end
  
  #to be overridden by interpreters
  def __init; end
  def __cleanup; end
  def __hidden_calls; []; end
  def __default_args; {}; end

  #misc 
  def to_s; "Interp(#{@this})"; end
  def to_ary; end

end

def Interpreter(*mods)
  Interpreter.new(*mods)
end

# easier to work with arguments
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
  end
  def operations
    @operations||=[]
    (@operations + included_modules.map{|mod|mod.operations||[]}.flatten).uniq
  end
  def op_methods
    instance_methods.select{|m|operations.detect{|op|m.to_s.start_with? "#{op}_"}}
  end
end
