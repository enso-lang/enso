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
  def any_value?
    each do |x|
      val = yield x
      return val if val
    end
    return false
  end
end

class Hash
  def has_key_P(x); has_key?(x); end
end

class Object
  def define_singleton_value(sym, val)
    self.define_singleton_method(sym) { val }
  end
  def is_a_P(x); is_a?(x); end
end

class EnsoBaseClass
  begin
    undef_method :lambda, :methods
  rescue
  end
  def type  # HACK for JRuby to work, because it defines :type
    method_missing(:type)
  end
end

class EnsoProxyObject < EnsoBaseClass
  def [](prop)
    send(prop)
  end
  def method_missing(msg, *args)
    if msg.slice(-1) == "="
      _set(msg.chomp, args[0])
    elsif msg == "[]"
      _get(args[0])
    else
      _get(msg)
    end
  end
end
