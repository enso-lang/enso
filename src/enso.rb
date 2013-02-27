def S(*args)
  args.join
end

module System
  def self.readJSON(path)
    JSON.parse(File.read(path), allow_nan: true, max_nesting: false)
  end
  def raise(error)
    raise error
  end
  def self.max(a, b)
    if a > b then a else b end
  end
end

class File
  def self.create_file_map(base)
    result = {}
    Dir["#{base}/**/*.*"].each do |p|
      ext = File.extname(p)
      if ext != ".rb" && ext != ".js"
        name = File.basename(p)
        result[name] = p
      end
    end
    result
  end
end

module Enumerable
  def find_first
    each do |x|
      val = yield x
      return val if val
    end
    return nil
  end

  def find_first_with_index
    i = 0
    each do |x|
      val = yield x, i
      return val if val
      i += 1
    end
    return nil
  end
end

class Hash
  def has_key_P(x); has_key?(x); end
  
  def find_first_pair
    self.each_pair do |x, y|
      val = yield x, y
      return val if val
    end
  end
end

class String
  def is_binary_data?
    ( self.count( "^ -~", "^\r\n" ).fdiv(self.size) > 0.3 || self.index( "\x00" ) ) unless empty?
  end
  
  def repeat n
    self * n
  end
end

class Object
  def define_singleton_value(sym, val)
    self.define_singleton_method(sym) { val }
  end
  def is_a_P(x)
    is_a?(x)
  end
end

class Array
  def union(a)
    return self | a
  end
end

class EnsoBaseClass
  begin
    undef_method :lambda, :methods, :method
  rescue
  end
  def to_ary
    nil
  end
end

class EnsoProxyObject < EnsoBaseClass  
  def [](name)
    send name
  end
  
  def []=(name, val)
    send "#{name}=", val
  end
  
  def define_singleton_value(name, value)
    define_singleton_method name do
      value
    end
  end
  
  def define_getter(name, accessor)
    define_singleton_method(name) do
      accessor.get
    end
  end

  def define_setter(name, accessor)
    define_singleton_method("#{name}=") do |val|
      accessor.set(val)
    end
  end
end
