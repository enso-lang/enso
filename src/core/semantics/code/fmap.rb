require 'core/semantics/code/interpreter'

class Fmap < Interpreter
  class CompObj
    def initialize(map)
      #map.nil? ? @hash={} : @hash=Hash[map.map{|k,v| ["#{k}", v]}]
      @hash={}
      map.each do |k,v|
        @hash["#{k}"]=v
        define_singleton_method(k.to_sym) { @hash[k.to_s] }
        define_singleton_method("#{k}=".to_sym) {|arg| @hash[k.to_s] = arg }
      end if !map.nil?
    end
    def to_s
      @hash.to_s
    end
  end

  def _interp(method_sym, obj, arguments=nil, &block)
    if respond_to?("#{method_sym}_#{obj.schema_class.name}") or respond_to?("#{method_sym}_?")
      m = method("#{method_sym}_#{obj.schema_class.name}".to_sym)

      #specific methods (eg "eval_Add") use only those fields specified in the method
      #generic methods (eg "eval_?") use all fields
      if respond_to?("#{method_sym}_#{obj.schema_class.name}")
        generic = false
      elsif respond_to?("#{method_sym}_?")
        generic = true
      end

      if !generic
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|obj.schema_class.fields[v.to_s]}
      else
        fields = obj.schema_class.fields
      end

      args = []
      fields.each do |f|
        if f.type.Primitive?
          args << obj[f.name]
        elsif !f.many
          args << _interp(method_sym, obj[f.name], arguments, &block)
        else
          l = obj[f.name].class.new
          self[f.name].each do |v|
            l << _interp(method_sym, v, arguments, &block)
          end
          args << l
        end
      end

      if !generic
        res = m.call(*args, arguments, &block)
      else
        res = m.call(args, arguments, &block)
      end
      if !res.is_a? CompObj
        res = CompObj.new(method_sym => res)
      end
      res
    else
      super
    end
  end

  def method_missing(method_sym, obj, arguments=nil, &block)
    _interp(method_sym, obj, arguments, &block).send(method_sym)
  end

end
