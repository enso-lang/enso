=begin
Base interpreter container. Operations must be rolled in before it is used
=end

require 'core/system/library/schema'

$t1 = 0
$t15= 0
$t2 = 0
$t3 = 0

class InterpError < Exception
end

class Interpreter3
  module Dispatch
    def method_missing(method_sym, *arguments, &block)
    
      obj = arguments[0]
      raise "Interpreter: obj is nil for method #{method_sym}" if obj.nil?
      #raise "Interpreter: invalid obj #{obj} for method #{method_sym}" if !obj.is_a? ManagedData::MObject
      args = arguments[1]
      raise "Interpreter: args is not a hash in #{obj}.#{method_sym}" if args and !args.is_a? Hash

      args ||= {}
      args[:self] = obj

      af = obj.schema_class.all_fields
    s1 = Time.now
      fields = Hash[af.map{|f|[nil,nil]}]
    $t15 += (Time.now - s1)
    s1 = Time.now
      fields = Hash[af.map{|f|[f.name,obj[f.name]]}]
    $t1 += (Time.now - s1)

      __call(method_sym, fields, obj.schema_class, args)

    end

    private

    def __call(method_sym, fields, type, args)
      begin
    s1 = Time.now
        m = Lookup(type) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
    $t2 += (Time.now - s1)
        if !m.nil?
    s1 = Time.now

          params = []
          m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}.each do |f|
            params << fields[f]
          end
    $t3 += (Time.now - s1)

          m.call(*params, args)
  
        elsif respond_to?("#{method_sym}_?")
          m = method("#{method_sym}_?".to_sym)
          m.call(fields, type, args)

        else
          raise "Unable to resolve method #{method_sym} for #{type}"
        end
      rescue Exception => e 
        puts "\tin #{args[:self]}.#{method_sym}(#{args})"
        raise e
      end
    end
  end

  include Dispatch

  def compose!(*mods)
    mods.each {|mod| instance_eval {extend(mod)}}
    initialize
    self
  end
end

def Interpreter3(*mods)
  Interpreter3.new.compose!(*mods)
end

# easier to work with args
class Hash
  def set!(key)
    self[key] = yield self[key]
  end
  def set(key, &block)
    res = self.clone
    res.set!(key, &block)
    res
  end
  def +(hash)
    merge(hash)
  end
end

