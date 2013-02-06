

module SchemaEval
  include CommandEval
  include SchemaObjects


  class Schema
    attr_reader :types
   
    def make(cls)
      types.each do |type|
        if type.is_a?(Class) && type.name == cls then
          type.create
        end
      end
      raise "No such class #{cls}"
    end
  end

  class Type
    attr_reader :name, :schema
  end

  class Primitive < Type
    def check_compatible(value)
      case name
      when 'str' then value.is_a?(String)
      when 'int' then value.is_a?(Integer)
      when 'bool' then value.is_a?(TrueClass) || value.is_a?(FalseClass)
      when 'real' then value.is_a?(Numeric)
      when 'datetime' then value.is_a?(DateTime)
      when 'atom' then true
      else 
        raise "Expected #{name} but got a #{value}"
      end
    end

    def default
      case name
      when 'str' then ''
      when 'int' then 0
      when 'bool' then false
      when 'real' then 0.0
      when 'datetime' then DateTime.now
      when 'atom' then nil
      else nil
      end
    end
  end

  class Class < Type
    attr_reader :defined_fields

    def create
      obj = Object.new
      fields.each do |fld|
        fld.init(obj)
      end
      return obj
    end

    def get(owner, name)
      lookup(name).get(owner)
    end

    def set(owner, name, value)
      lookup(name).set(owner, value)
    end

    def insert(owner, name, value)
      lookup(name).insert(owner, value)
    end

    def key
      fields.find(&:key)
    end

    def default
      nil
    end

    def check_compatible(value)
      if !value.respond_to?(:schema_class)
        raise "Expected managed object, not #{value}"
      end
      if !Schema::subclass?(value.schema_class, self) then
        raise "Incompatible class #{value.schema_class.name} with type #{name}"
      end
      if value._graph_id != schema then
        raise "Inserting object #{value} into wrong model"
      end
    end

    private

    def lookup(name)
      all_fields.each do |fld|
        if fld.name == name then
          return fld
        end
      end
      raise "No such field #{name}"
    end

    def fields
    end
    def all_fields
    end
  end

  class Field
    attr_reader :name, :type, :optional, :many, :computed

    def init(obj)
      return if computed
      if many then
        obj.__set(name, type.key ? Set.new(obj, self) : List.new(obj, self))
      else
        obj.__set(name, Single.new(obj, self, type.default)
      end
    end

    def check_assignable(value)
      if computed then
        raise "Cannot asign to computed field #{name}"
      end
      if !optional && value.nil? then
        raise "Cannot assign nil to non-optional field #{name}"
      end
      if many then
        raise "Cannot assign to many-valued field #{name}"
      end
      type.check_compatible(value)
    end

    def get(owner)
      if computed then
        computed.eval(object_env(owner))
      else
        owner.__get(name)
      end
    end

    def set(owner, value)
      check_assignable(value)
      owner.__set(name, value)
    end

    def insert(owner, value)
      check_insertable(value)
      owner.__get(name).__insert(value, type.key)
    end

    def check_insertable(value)
      if !many then
        raise "Cannot insert into single-valued field #{name}"
      end
      if type.key && value.nil? then
        raise "Cannot insert nil into keyed field #{name}"
      end
      type.check_compatible(value)
    end
  end


end
