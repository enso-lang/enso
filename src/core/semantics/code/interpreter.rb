=begin
Base interpreter container. Operations must be rolled in before it is used
=end

require 'core/system/library/schema'

class Interpreter
  module Dispatch
    def method_missing(method_sym, *arguments, &block)
      obj = arguments[0]
      raise "Interpreter: obj is nil for method #{method_sym}" if obj.nil?
      raise "Interpreter: invalid obj for method #{method_sym}" if !obj.is_a? ManagedData::MObject
      args = arguments[1]
      raise "Interpreter: args is not a hash in #{obj}.#{method_sym}" if args and !args.is_a? Hash

      args ||= {}
      args[:self] = obj
      m = Lookup(obj.schema_class) {|o| m = "#{method_sym}_#{o.name}"; method(m.to_sym) if respond_to?(m) }
      if !m.nil?
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

        params = []
        fields.each do |f|
          params << obj[f]
        end

        m.call(*params, args)
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym)
        fields = obj.schema_class.all_fields

        params = {}
        fields.each do |f|
          params[f.name] = obj[f.name]
        end

        m.call(params, obj.schema_class, args)
      else
        nil
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
