require 'core/semantics/code/interpreter'

class Visitor < Interpreter

  def method_missing(method_sym, obj, arguments=nil, &block)
      if respond_to?("#{method_sym}_#{obj.schema_class.name}") or respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_#{obj.schema_class.name}".to_sym)

        #specific methods (eg "eval_Add") use only those fields specified in the method
        #generic methods (eg "eval_?") use all fields
        if respond_to?("#{method_sym}_#{obj.schema_class.name}")
          generic = false
        elsif respond_to?("#{method_sym}_?")
          generic = true
        end

        puts "m is #{m}"
        puts "m params #{m.parameters}"
        puts "m params2 #{m.parameters.select{|k,v|k==:req}}"
        if !generic
          fields = m.parameters.select{|k,v|k==:req}.map{|k,v|obj.schema_class.fields[v.to_s]}
        else
          fields = obj.schema_class.fields
        end

        puts "fields = #{fields}"
        params = []
        fields.each do |f|
          params << obj[f.name]
        end

        puts "From visitor: params=#{params}"
        generic ? m.call(params, arguments) : m.call(*params, arguments)
      else
        super
      end
  end
end

=begin
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

#This is an internal visitor
class Visitor < Interpreter

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
=end

=begin
class Implicit < Hash
  def method_missing(method_sym, *arguments, &block)
    Implicit[*self.map {|k,v| [k, v.is_a?(Hash) ? v[method_sym] : v]}.flatten]
  end
end

module ExternalVisitor

  def method_missing(method_sym, *arguments, &block)
    if respond_to?("#{method_sym}_#{schema_class.name}") or respond_to?("#{method_sym}_?")
      fields = Implicit.new
      schema_class.fields.each do |f|
        fields[f.name] = self[f.name]
      end
      send("#{method_sym}__", fields, *arguments, &block)
    elsif method_sym =~ /(.*)__/
      if respond_to?("#{$1}_#{schema_class.name}")
        send("#{$1}_#{schema_class.name}", *(arguments[0].map{|x|x[1]}), *(arguments[1..-1]), &block)
      else
        send("#{$1}_?", *arguments, &block)
      end
    else
      super
    end
  end
end

module InternalVisitor

  def method_missing(method_sym, *arguments, &block)
    if respond_to?("#{method_sym}_#{schema_class.name}") or respond_to?("#{method_sym}_?")
      fields = Implicit.new
      schema_class.fields.each do |f|
        if f.type.Primitive?
          fields[f.name] = self[f.name]
        elsif !f.many
          fields[f.name] = self[f.name].send(method_sym, *arguments, &block)
        else
          l = self[f.name].class.new
          self[f.name].each do |v|
            l << v.send(method_sym, *arguments, &block)
          end
          fields[f.name] = l
        end
      end
      send("#{method_sym}__", fields, *arguments, &block)
    elsif method_sym =~ /(.*)__/
      if respond_to?("#{$1}_#{schema_class.name}")
        send("#{$1}_#{schema_class.name}", *(arguments[0].map{|x|x[1]}), *(arguments[1..-1]), &block)
      else
        send("#{$1}_?", *arguments, &block)
      end
    else
      super
    end
  end
end
=end
