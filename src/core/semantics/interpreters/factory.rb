require 'core/schema/code/factory2'

module FactorySchema
  include ManagedData

  class Factory < ManagedData::Factory

    attr_accessor :interp

    def initialize(schema)
      @schema = schema
      @roots = []
      __constructor(schema.types)
    end

    def __constructor(klasses)
      klasses.each do |klass|
        define_singleton_method(klass.name) do |*args|
          @interp.Make(klass, :args=>args, :obj=>klass, :factory=>self)
        end
      end
    end
  end

  class MObject < ManagedData::MObject
    attr_accessor :interp
    def __setup(fields)
      fields.each do |fld|
        __set(fld.name, @factory.interp.Make(fld, :class=>self))
      end
    end
  end

  def Make_Schema(args=nil)
    res = Factory.new(args[:self])
    res.interp = self
    res
  end

  def Make_Class(args=nil)
    MObject.new(args[:self], args[:factory], *args[:args])
  end

  def Make_Field(computed, many, type, args=nil)
    fld = args[:self]
    klass = args[:class]
    if computed then
      :computed
    elsif type.Primitive? then
      ManagedData::Prim.new(klass, fld)
    elsif !many then
      ManagedData::Ref.new(klass, fld)
    elsif key = ClassKey(type) then
      ManagedData::Set.new(klass, fld, key)
    else
      ManagedData::List.new(klass, fld)
    end
  end
end
