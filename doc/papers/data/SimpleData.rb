Fixnum.send(:define_method, :default) { 0 }
String.send(:define_method, :default) { "" }

class Fixnum
   class <<self
     def default
       0
     end
   end
end

class String
   class <<self
     def default
       ""
     end
   end
end

class SimpleDataManager
  def initialize(types)
    @types = types
    @values = {}
    puts types
    types.each_pair do |key, type| 
      @values[key] = type.default
    end
  end
  def method_missing(name, *args)
    assign = (name =~ /(.*)=/)
    name = $1.to_sym if assign
    raise "unknown field #{name}" if !@types[name]
    if assign
      raise "#{name} must be #{@types[name]}" if @types[name] != args[0].class
      @values[name] = args[0]
    else
      return @values[name]
    end
  end
end

  
  x = SimpleDataManager.new :foo => Fixnum, :bar => String
  puts x.foo
  puts x.foo.class
  x.foo = 32
  #x.foo = "asdf"
  #x.baz
  puts x.foo
  