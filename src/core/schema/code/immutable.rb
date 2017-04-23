require 'core/semantics/code/interpreter'


module ImmutableFactory

  class ImmutableList
    def initialize(items)
      @items = items
    end

    def each(&block)
      @items.each &block      
    end
  end
  

  class ManagedObjectBase
    class << self
      public :define_method
    end
  end

  def self.new(schema)
    ImmutableFactory.new(schema)
  end

  # every model/graph should have its own factory, which "owns" the nodes of the graph  
  class ImmutableFactory
    attr_reader :schema
    attr_accessor :file_path

    include Interpreter::Dispatcher    
      
    def initialize(schema)
      @schema = schema
      @roots = []
      @file_path = []
      setup(@schema)
    end

    def setup(obj)
      dispatch_obj(:setup, obj)
    end

    # make factory.["Foo"] equivalent to factory.Foo
    def [](name)
      send(name)
    end
    
    def register(root)
      #raise "Creating two roots" if @root
      @root = root
    end
    
    # for every class in the schema, create the factory methods
    def setup_Schema(schema)
      schema.classes.each do |klass|
        setup(klass)
      end
    end

    def setup_Class(klass)
      # all managed objects are subclass of a standard base class
      c = Class.new(ManagedObjectBase)
      dynamic_bind class: c do
        klass.all_fields.each do |field|
          setup(field)
        end
      end
      _create_factory_method(klass, c)
      _create_initialize_method(klass, c)
    end

    # this is a helper method that can be overiden    
    def _create_factory_method(klass, c)
      define_singleton_method(klass.name) do |*args|
        c.new(self, *args)
      end 
    end
    
    # this is a helper method that can be overiden    
    def _create_initialize_method(klass, c)
      # this local variable allows the created initialize method to call back to the
      # data model interpreter
      interpreter = self
      c.define_method(:initialize) do |factory, *args|
        # initialize all the data of the object
        klass.fields.each_with_index do |fld, i|
          if i >= args.size && !fld.optional
            raise "Creating immutable object without initializing all required fields"
          end
          if fld.many then
            # don't use << to insert into the collection, because it should be immutable.
            # create an indexed or non-indexed collection depending on fld.key
            if fld.key
              val = ImmutableSet.new(i < args.size ? args[i] : [])
            else
              val = ImmutableList.new(i < args.size ? args[i] : [])
            end
          else
            val = i < args.size ? args[i] : nil
          end
          instance_variable_set("@#{fld.name}", val)
        end
      end 
    end

    def setup_Field(fld)
      if fld.computed then
        setup_computed(@D[:class], fld)
      else
        define_getter(@D[:class], fld)
      end
    end

    def define_getter(c, fld)
      c.define_method(fld.name.to_sym) do ||
        instance_variable_get("@#{fld.name}")
      end
    end
    
    def setup_computed(c, fld)
      exp = fld.computed
      # compute it once, because it must be constant
      computed = false
      c.define_method(fld.name) do
        if !computed
          val = Impl::eval(exp, env: Env::ObjEnv.new(self))
          computed = true
        end
        val
      end
    end
  end
end
