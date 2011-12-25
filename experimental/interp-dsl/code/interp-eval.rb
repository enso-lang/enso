
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/schema/tools/union'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-type.rb'
require 'set'

class Interpreter

  attr_accessor :interp

  def initialize(*interps)
    @actions = Set.new
    @types = Set.new
    interps.each {|i| self << i}
  end

  def <<(interp)
    action = interp.action
    @actions << action
    if not self.singleton_methods.include? action.to_sym
      self.define_singleton_method("#{action}") do |obj, *args|
        type = obj.schema_class
        fields = {}
        type.fields.each do |f|
          fields[f.name] = f.type.Primitive? ? obj[f.name] : send("#{action}", obj[f.name], *args)
        end
        send("#{action}_#{obj.schema_class.name}", fields).call(*args)
      end
    end
    interp.rules.each do |r|
      @types << r.type
      funname = "#{action}_#{r.type}"
      self.define_singleton_method(funname) do |fields|
        lambda { |*args|
          prepend = ""
          fields.keys.each do |fk|
            prepend += "#{fk} = fields[\"#{fk}\"]\n"
          end
          i=0
          interp.args.each do |formal|
            prepend += "#{formal.name} = args[#{i}]\n"
            i+=1
          end
          Kernel::eval(prepend+interp.rules[r.type].body.gsub('\'','"'), binding)
        }
      end
    end
  end

  def compose_varinterp(action, &block)
    interps = block.parameters.map{|p|p[1].to_s}.reject{|p|p=="_fields" or p=="_type"}
    self.define_singleton_method("#{action}") do |obj, *args|
      type = obj.schema_class
      fields = {}
      type.fields.each do |f|
        fields[f.name] = f.type.Primitive? ? Hash.new{obj[f.name]} : send("#{action}", obj[f.name], *args)
      end
      send("#{action}_#{obj.schema_class.name}", fields).call(*args)
    end
    @types.each do |type|
      funname = "#{action}_#{type}"
      self.define_singleton_method(funname) do |_fields|
        lambda { |*args|
          myargs = block.parameters.map do |p|
            argname = p[1].to_s
            if argname == '_fields'
              _fields
            elsif argname == '_type'
              type
            else
              proc do |f=Hash[*_fields.map{|k,v| [k, v[argname]]}.flatten], *args2|
                args2 = args if args2.empty?
                send("#{argname}_#{type}", f).call(*args2)
              end
            end
          end
          block.call(*myargs)
        }
      end
    end
  end

end

=begin
interesting observations:

- side effects? sequencing of side effects?
- no shared mutable state
- no arguments

=end
