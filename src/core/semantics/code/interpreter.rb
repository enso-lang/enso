=begin
Base interpreter container. Operations must be rolled in before it is used
=end

require 'core/system/library/schema'

class Interpreter
  def initialize(*mods)
    @all_interps = {}    #Note that this is a generic hashtable, so keys may be anything from 
                         # MObjects to Lists & Sets to even primitives
    @mods = mods
    method_syms = mods.map{|m|Interpreter.methods_from_mod(m)}.flatten.uniq #2nd uniq because two mods can def same method
    method_syms.each do |method_sym|
      define_singleton_method(method_sym) do |obj, *args|
        get_interp(obj).send(method_sym, *args)
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
      if IsKeyed?(field.type); newl = {}
      else; newl = []; end
      obj.each {|val| newl << make_interp(val)}
      newl
    end
  end

  def self.methods_from_mod(mod)
    mod.instance_methods.select{|m|m.to_s.include? "_"}.map{|m|m.to_s.split("_")[0]}.uniq
  end
end

class Interp
  #TODO: Undef some methods here, but make sure not to undef the later defined ones
  #ie DON'T use "undef"
  #begin; undef_method :lambda, :methods; rescue; end

  def initialize(obj, interpreter, mods=[])
    @obj=obj
    @interpreter=interpreter
    @mods=mods

    mods.each {|mod| instance_eval {extend(mod)}}
    method_syms = @mods.map{|m|Interpreter.methods_from_mod(m)}.flatten.uniq #2nd uniq because two mods can def same method
    method_syms.each do |method_sym|
      m = Lookup(@obj.schema_class) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
      if !m.nil?
        param_names = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

        define_singleton_method(method_sym) do |args={}, &block|
          params = param_names.map{|p|@interpreter.get_interp(@obj[p], @obj.schema_class.fields[p])}
          m.call(*params, args, &block)
        end
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym) 
        param_names = @obj.schema_class.all_fields.map{|f|f.name}

        define_singleton_method(method_sym) do |args={}, &block|
          params = Hash[*param_names.map{|p|[p, @interpreter.get_interp(@obj[p], @obj.schema_class.fields[p])]}.flatten(1)]
          m.call(@obj.schema_class, params, args, &block)
        end
      else
        #$stderr << "Cannot find method #{method_sym} for #{@obj}\n"
        #define_singleton_method(method_sym) do |*args| #this is necessary because method_missing is not 
                                                       #called for methods inherited from Object, eg 'eval'  
        #  self[method_sym]
        #end
      end
    end
  end
  
  def method_missing(method_sym, *args)
    if @obj.schema_class.fields.map{|f|f.name}.include?(method_sym.to_s)
      self[method_sym]
    else 
      super
    end
  end
  
  def [](key=nil)
    return @obj if key.nil?
    if field = @obj.schema_class.fields[key.to_s]
      @interpreter.get_interp(@obj[key.to_s], field)
    end
  end

  def to_s; "Interp(#{@obj})"; end
  def to_ary; end
end

def Interpreter(*mods)
  Interpreter.new(*mods)
end

# easier to work with args
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
