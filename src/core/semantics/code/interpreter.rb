=begin
Base interpreter container. Operations must be rolled in before it is used
=end

require 'core/system/library/schema'

class Interpreter
  module Dispatch
    def method_missing(method_sym, obj, arguments=nil, &block)
      if arguments and !arguments.is_a? Hash
        raise "Arguments is not a hash! in #{method_sym} #{obj}"
      end
      arguments ||= {}
      arguments[:self] = obj
      m = Lookup(obj.schema_class) {|o| method("#{method_sym}_#{o.name}".to_sym) if respond_to?("#{method_sym}_#{o.name}") }
      if !m.nil?
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

        params = []
        fields.each do |f|
          params << obj[f]
        end

        m.call(*params, arguments)
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_?".to_sym)
        fields = obj.schema_class.all_fields

        params = {}
        fields.each do |f|
          params[f.name] = obj[f.name]
        end

        m.call(params, obj.schema_class, arguments)
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
