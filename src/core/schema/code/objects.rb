
module SchemaObjects
  class Object
    attr_reader :schema_class

    def initialize(cls)
      @hash = {}
      @schema_class = cls
    end

    def [](name)
      schema_class.get(self, name)
    end

    def []=(name, value)
      schema_class.set(self, name, value)
    end

    def __set(name, value)
      @hash[name] = value
    end

    def __get(name)
      @hash[name]
    end
  end

  class Set
    def initialize(owner, field, key_field)
      @owner = owner
      @field = field
      @key_field = key_field
      @hash = {}
    end

    def <<(value)
      @field.insert(self, value)
    end

    def each(&block)
      @hash.values.each(&block)
    end
    
    def __insert(value)
      key = value[@key_field]
      if @hash.has_key?(key) then
        raise "Duplicate key #{key} when inserting #{value} into #{@field.name}"
      end
      @hash[key] = value
    end

    def __delete(value)
      key = value[@key_field]
      if @hash.has_key?(key) then
        @hash.delete(key)
      end
    end
  end

  class List
    def initialize(owner, field)
      @owner = owner
      @field = field
      @list = []
    end

    def <<(value)
      @field.insert(self, value)
    end

    def each(&block)
      @list.each(&block)
    end

    def __insert(value)
      @list << value
    end

    def __delete(value)
      @list.delete(value)
    end
  end
  
  class Single
    attr_accessor :value
    def initialize(owner, field, default)
      @owner = owner
      @field = field
      @value = default
    end
  end
end
