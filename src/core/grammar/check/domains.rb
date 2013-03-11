
require 'core/grammar/check/types'
require 'core/grammar/check/mult'

module AbstractDomains

  class Schema
    def initialize(types = {})
      @types = types
    end

    def +(schema)
      merge(schema, :+)
    end

    def *(schema)
      merge(schema, :*)
    end

    def [](name)
      @types[name]
    end

    def names
      @types.keys
    end

    def opt
      regularize(:opt)
    end

    def star
      regularize(:star)
    end

    def plus
      regularize(:plus)
    end

    
    private

    def regularize(sym)
      types = {}
      names.each do |n|
        types[n] = self[n].send(sym)
      end
      Schema.new(types);
    end

    def merge(schema, op)
      types = {}
      (names & schema.names).each do |name|
        types[name] = self[name].send(op, schema[name])
      end
      (names - schema.names).each do |name|
        types[name] = self[name]
      end
      (schema.names - names).each do |name|
        types[name] = schema[name]
      end
      return Schema.new(types)
    end
  end
  
  class Fields
    BOTTOM = Type.new(GrammarTypes::VOID, Multiplicity::ZERO)

    def initialize(fields = {})
      @fields = fields
    end

    def +(other)
      merge(other, :+)
    end

    def *(other)
      merge(other, :*)
    end

    def names
      @fields.keys
    end

    def [](name)
      @fields[name]
    end

    def opt
      regularize(:opt)
    end

    def star
      regularize(:star)
    end

    def plus
      regularize(:plus)
    end

    
    private

     def regularize(sym)
      flds = {}
      names.each do |n|
        flds[n] = self[n].send(sym)
      end
      Fields.new(flds);
    end


    def merge(fields, op)
      flds = {}
      (names & fields.names).each do |name|
        flds[name] = self[name].send(op, schema[name])
      end
      (names - fields.names).each do |name|
        flds[name] = self[name].send(op, BOTTOM)
      end
      (fields.names - names).each do |name|
        flds[name] = schema[name].send(op, BOTTOM)
      end
      return Fields.new(flds)
    end
  end

  class Type
    attr_reader :type, :mult

    def initialize(type, mult)
      @type = type
      @mult = mult
    end

    def opt
      regularize(:opt)
    end

    def star
      regularize(:star)
    end

    def plus
      regularize(:plus)
    end


    def +(other)
      Type.new(type + other.type, mult + other.mult)
    end

    def *(type)
      Type.new(type * other.type, mult * other.mult)
    end

    private

    def regularize(sym)
      Type.new(type, mult.send(sym))
    end
  end
end

  
