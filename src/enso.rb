def str(*args)
  args.join
end

module System
  def self.readJSON(path)
    JSON.load(File.new(path))
  end
end
  
def makeProxy x
  x
end

class Object
  def define_singleton_value(sym, val)
    self.define_singleton_method(sym) { val }
  end
end

class EnsoBaseObject
    begin
      undef_method :lambda, :methods
    rescue
    end
    def type  # HACK for JRuby to work, because it defines :type
      method_missing(:type)
    end
    def [](prop)
      send(prop)
    end
    def method_missing(msg, *args)
      if msg.slice(-1) == "="
        set(msg.chomp, args[0])
      elsif msg == "[]"
        get(args[0])
      else
        get(msg)
      end
    end
end

