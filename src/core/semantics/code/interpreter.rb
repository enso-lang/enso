=begin
Base interpreter container. Operations must be rolled in before it is used
=end

require 'core/system/library/schema'

class Interpreter
  module Dispatch
    def method_missing(method_sym, *arguments, &block)
      puts "MM #{method_sym} #{arguments}"
      obj = arguments[0]
      raise "Interpreter: obj is nil for method #{method_sym}" if obj.nil?
      raise "Interpreter: invalid obj for method #{method_sym}" if !obj.is_a? ManagedData::MObject
      args = arguments[1]
      raise "Interpreter: args is not a hash in #{obj}.#{method_sym}" if args and !args.is_a? Hash

      args ||= {}
      args[:self] = obj

      fields = Hash[obj.schema_class.all_fields.map{|f|[f.name,obj[f.name]]}]
      __call(method_sym, fields, obj.schema_class, args)

    end

    private

    def __call(method_sym, fields, type, args)
      puts "Callin #{type}.#{method_sym} #{fields} #{args}"
      m = Lookup(type) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
      if !m.nil?
        params = []
        m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}.each do |f|
          params << fields[f]
        end
        m.call(*params, args)

      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym)
        m.call(fields, type, args)

      else
        raise "Interpreter: Unable to resolve method #{method_sym} for #{obj}"
      end
    end
  end

  include Dispatch

  def self.compose(*mods)
    r = self.clone
    mods.each {|mod| r.instance_eval {include(mod)}}
    r
  end
end

def Interpreter(*mods)
  Interpreter.compose(*mods).new()
end
