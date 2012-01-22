require 'core/schema/code/factory2'

module FactorySchema
  include ManagedData

  class Factory < ManagedData::Factory

    def initialize(schema)
      @schema = schema
      @roots = []
      __constructor(schema.types)
    end

    def __constructor(klasses)
      klasses.each do |klass|
        define_singleton_method(klass.name) do |*args|
          Make(klass, {:args=>args, :obj=>klass, :factory=>self})
        end
      end
    end
  end

  class MObject < ManagedData::MObject
    def __setup(fields)
      fields.each do |fld|
        __set(fld.name, Make(fld))
      end
    end
  end

  def Make_Schema(args=nil)
    Factory.new(args[:obj])
  end

  def Make_Class(args=nil)
    MObject.new(args[:obj], args[:factory], args[:args])
  end

  def Make_Field(computed, many, type, args=nil)
    fld = args[:obj]
    if fld.computed then
      :computed
    elsif type.Primitive? then
      ManagedData::Prim.new(self, fld)
    elsif !many then
      ManagedData::Ref.new(self, fld)
    elsif key = ClassKey(type) then
      ManagedData::Set.new(self, fld, key)
    else
      ManagedData::List.new(self, fld)
    end
  end
end
