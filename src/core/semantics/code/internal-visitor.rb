
module InternalVisitorMod
  def self.init(action, mod)
    r = InternalVisitorMod.clone
    r.class_exec do
      @@action = action
      include mod
    end
    r.send(:define_method, :initialize) do |*args|
      @action = action
      super(*args)
    end
    r
  end

  class InternObj
    def initialize(name=nil, val=nil)
      @hash = {}
      @hash[name] = val if !name.nil?
    end

    def method_missing(method_sym, *args)
      if not method_sym.to_s.end_with? "="
        @hash[method_sym.to_s]
      else
        @hash[method_sym[0..-2].to_s] = args[0]
      end
    end

    def [](s)
      @hash[s]
    end

    def []=(s,v)
      @hash[s] = v
    end
  end

  def visit_?(fields, type, args=nil)
    method_sym = @action
    m = Lookup(type) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
    if !m.nil?
      params = []
      m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}.each do |f|
        val = fields[f]
        if type.fields[f].type.Primitive?
          params << val
        elsif !type.fields[f].many
          params << InternObj.new(@action, visit(val, args))
        else
          l = val.class.new
          val.each do |v|
            l << visit(v, args)
          end
          params << InternObj.new(@action, l)
        end
      end
      m.call(*params, args)
    elsif respond_to?("#{method_sym}_?")
      m = method("#{method_sym}_?".to_sym)
      params = {}
      fields.keys.each do |f|
        val = fields[f]
        if f.type.Primitive?
          params[f.name] = val
        elsif !f.many
          params[f.name] = InternObj.new(@action, visit(val, args))
        else
          l = val.class.new
          val.each do |v|
            l << visit(v, args)
          end
          params[f.name] = InternObj.new(@action, l)
        end
      end
      m.call(params, type, args)
    end
  end
end

def InternalVisitor(*args)
  InternalVisitorMod.init(*args)
end
