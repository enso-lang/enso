def S(*args)
  args.join
end

module System
  def self.readJSON(path)
    JSON.load(File.new(path))
  end
  def raise(error)
    raise error
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

class Object
  def define_singleton_value(sym, val)
    self.define_singleton_method(sym) { val }
  end
  def is_a_P(x)
    is_a?(x)
  end
end

class EnsoBaseClass
  begin
    undef_method :lambda, :methods, :method
  rescue
  end
  def type  # HACK for JRuby to work, because it defines :type
    method_missing(:type)
  end
  def to_ary
    nil
  end
end

class EnsoProxyObject < EnsoBaseClass  
  def method_missing(msg, *args)
    #puts "MM #{msg} #{self.class}"
    if msg[-1] == "="
      self[msg.to_s.chomp("=")] = args[0]
    elsif msg == "[]" || args.length == 1
      self[args[0]]
    elsif args.length == 0
      self[msg.to_s]
    else
      raise "Method missing only works for properties and []"
      #_call(msg, *args)
    end
  end
end
