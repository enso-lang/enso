class Variable
  def initialize(name, val = nil)
    @name = name
    @vars = []
    @dependencies = []
    @value = val
  end

  attr_reader :name
  def to_s
    return name
  end
  
  def self.compute(name, *vars, &block)
    self.new(name).compute(*vars, &block)
  end
  
  def compute(*vars, &block)
    @aggregate = vars[0].is_a?(Array) && vars.length == 1
    vars = vars[0] if @aggregate
    @vars = vars
    #puts "#{vars}"
    @block = block
    evaluate unless @value 
    return self
  end
  
  def evaluate(path = [])
    return @value unless @block
    raise "circular constraint #{path.collect(&:to_s)}" if path.include?(self)
    path << self
    vals = @vars.collect do |var|
      var.evaluate(path)
    end
    path.pop
    self.value = @aggregate ? @block.call(vals) : @block.call(*vals)
  end

  def add_listener(x)
    @dependencies << x
  end

  def notify
    @dependencies.each do |var|
      var.notify
    end
    @value = nil if @block
  end
    
  def value
    evaluate unless @value
    return @value
  end
  
  def value=(x)
    notify
    @value = x
  end
end
  


class Equality

  def initialize(a, b)
    puts "--- #{a} == #{b} ---"
    transform(a, b)
    transform(b, a)
  end

  def free_var(a)
    if a.is_a?(Variable)
      return a
    elsif a.is_a?(Array)
      a.each_with_index do |x, i|
        next if i == 0
        x = free_var(x)
        return x if x
      end
    end 
    return nil
  end
  
  def evaluate(a)
    if a.is_a?(Variable)
      return a.value
    elsif a.is_a?(Array)
      case [a[0], a.length]
      when [:+, 3]
        return evaluate(a[1]) + evaluate(a[2])
      when [:-, 3]
        return evaluate(a[1]) - evaluate(a[2])
      when [:-, 2]
        return -evaluate(a[1])
      when [:*, 3]
        return evaluate(a[1]) * evaluate(a[2])
      when [:/, 3]
        return evaluate(a[1]) / evaluate(a[2])
      else
        raise "Unknown expression #{a} == #{b}"
      end
    else
      return a
    end 
  end  

  def transform(a, b)
    if a.is_a?(Variable)
      puts "#{a} = #{b}"
      a.compute(free_var(b)) do |env|
        return evaluate(b)
      end
    elsif a.is_a?(Integer)
      return
    else
      case [a[0], a.length]
      when [:+, 3]
        transform(a[1], [:-, b, a[2]])     # A + x == z   ==>  A == z - x 
        transform(a[2], [:-, b, a[1]])     # x + A == z   ==>  A == z - x 
      when [:-, 3]
        transform(a[1], [:+, a[2], b])     # A - x == z   ==>  A == x + z 
        transform(a[2], [:-, a[1], b])     # x - A == z   ==>  A == x - z 
      when [:-, 2]
        transform(a[1], [:-, b])           # -A == z   ==>  A == x + z 
      when [:*, 3]
        transform(a[1], [:/, b, a[2]])     # A * x == z   ==>  A == z / x 
        transform(a[2], [:/, b, a[1]])     # x * A == z   ==>  A == z / x 
      when [:/, 3]
        transform(a[1], [:*, a[2], b])     # A / x == z   ==>  A == x * z 
        transform(a[2], [:/, a[1], b])     # x / A == z   ==>  A == x / z
      else
        raise "Unknown expression #{a} == #{b}"
      end
    end 
  end
end
