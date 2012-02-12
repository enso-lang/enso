require 'core/semantics/code/interpreter'

module FmapMod
  def self.init(mod)
    r = InternalVisitorMod.clone
    r.class_exec do
      include mod
    end
    r
  end

  def fmap_?(fields, type, args=nil)
    if @memo[:self]
      @memo[:self]
    else
      method_sym = args[:map]
      m = Lookup(type) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
      if !m.nil?
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}
        params = []
        fields.each do |f|
          params << obj[f]
        end

        m.call(*params, args) do |res|
          @memo[:self] = res
        end
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym)
        fields = obj.schema_class.all_fields

        params = {}
        fields.each do |f|
          params[f.name] = obj[f.name]
        end

        m.call(params, obj.schema_class, args) do |res|
          @memo[:self] = res
        end
      else
        nil
      end
    end
  end
end

def Fmap(*args)
  FmapMod.init(*args)
end

module Clone
  def clone_?(fields, type, args={})
    fact = args[:factory]
    res = fact[type]
    yield res
    fields.each do |k,v|
      res[k] = v
    end
    res
  end
end

