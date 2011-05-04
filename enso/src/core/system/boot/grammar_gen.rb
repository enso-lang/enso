
require 'schema/factory'
require 'grammar/grammarschema'

class GrammarGenerator

  THE_SCHEMA = GrammarSchema.schema
  THE_FACTORY = Factory.new(GrammarSchema.schema)
  
  @@grammars = {}

  def self.class_for(name)
    klass = THE_SCHEMA.classes[name]
    raise "Unknown class #{name}" unless klass
    return klass
  end

  def self.make_value(kind)
    v = THE_FACTORY.Value()
    v.kind = kind
    v
  end

  VALUES = {}
  %w(str int real sym bool). each do |t|
    VALUES[t.to_sym] = make_value(t.to_s)
  end

  def self.inherited(subclass)
    g = THE_FACTORY.Grammar(subclass.to_s)
    @@grammars[subclass.to_s] = g
  end

  def self.grammar
    @@grammars[self.to_s]
  end

  class << self

    def start(r)
      grammar.start = r
    end

    def rule(r)
      grammar.rules << r
      @@current = r
      yield
    end

    def alt(*elts)
      if elts[0].is_a?(Array)
        a = THE_FACTORY.Create(elts.shift.first.to_s)
        a.arg = THE_FACTORY.Sequence()
        s = a.arg
      else
        a = THE_FACTORY.Sequence()
        s = a
      end
      elts.each do |e|
        if e.is_a?(String) then
          l = THE_FACTORY.Lit(e)
          #l.case_sensitive = true
          s.elements << l
        elsif e.is_a?(Hash) then
          e.each do |k, v|
            s.elements << THE_FACTORY.Field(k.to_s, make_pattern(v))
          end
        else
          s.elements << make_pattern(e)
        end
      end
      @@current.arg.alts << a
    end
    
    def make_pattern(e)
      if e == :key then
        return THE_FACTORY.Key()
      end
      if e.is_a?(String) then
        l = THE_FACTORY.Lit(e)
        #l.case_sensitive = true
        return l
      elsif e.is_a?(Symbol)
        r = VALUES[e]
        raise "Unrecognized grammar symbol #{e}" unless r
        return r
      end
      if e.Rule? then
        return THE_FACTORY.Call(e)
      end
      return e
    end
    
    def ref(r)
      THE_FACTORY.Ref(r.name)
    end

    def code(s)
      THE_FACTORY.Code(s)
    end

    def iter(sym)
      reg = THE_FACTORY.Regular()
      reg.arg = make_pattern(sym)
      reg.optional = false
      reg.many = true
      reg.sep = nil
      return reg
    end
    
    def iter_star(sym)
      reg = THE_FACTORY.Regular()
      reg.arg = make_pattern(sym)
      reg.optional = true
      reg.many = true
      reg.sep = nil
      return reg
    end
    
    def iter_sep(sym, sep)
      reg = THE_FACTORY.Regular()
      reg.arg = make_pattern(sym)
      reg.optional = false
      reg.many = true
      reg.sep = sep
      #reg.sep.case_sensitive = true
      return reg
    end

    def iter_star_sep(sym, sep)
      reg = THE_FACTORY.Regular()
      reg.arg = make_pattern(sym)
      reg.optional = true
      reg.many = true
      reg.sep = sep
      #reg.sep.case_sensitive = true
      return reg
    end
    
    def opt(sym)
      reg = THE_FACTORY.Regular()
      reg.arg = make_pattern(sym)
      reg.optional = true
      reg.many = false
      reg.sep = nil
      return reg
    end

#     def cilit(s)
#       cl = THE_FACTORY.Lit(s)
#       cl.case_sensitive = false
#       return cl
#     end
      
    def const_missing(name)
      get_rule(name.to_s)
    end

    def get_rule(name)
      m = grammar.rules[name]
      if !m
        m = THE_FACTORY.Rule(name)
        m.arg = THE_FACTORY.Alt()
        grammar.rules << m
      end
      return m
    end
      
  end
end
