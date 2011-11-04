class SimpleDataManager
  def initialize(initial_values)
    @types = {}
    initial_values.each_pair { |key, value| @types[key] = value.class }
    @values = initial_values
  end
  def method_missing(name, *args)
    if name =~ /(.*)=/
      name = $1.to_sym
      raise "unknown field '#{name}'" if !@types.has_key?(name)
      raise "'#{name}' must be #{@types[name]}" if @types[name] != args[0].class
      @values[name] = args[0]
    else
      raise "unknown field '#{name}'" if !@types.has_key?(name)
      return @values[name]
    end
  end
end
  
  x = SimpleDataManager.new :foo => 3, :bar => "test"
  puts x.foo
  x.foo = 32
  #x.foo = "asdf"
  puts x.foo