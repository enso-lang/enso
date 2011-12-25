require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-type.rb'

class Interpreter

  def initialize(interp)
    @interp = interp
    #add init stuff to the object methods
    #these should mostly be function defs --- though here I am giving them the keys to the city!
    Kernel::eval(@interp.init.gsub('\'','"')) if !@interp.init.nil?

    self.define_singleton_method(@interp.action) do |*args|
      prepend = ""
      for i in (0..@interp.args.length-1)
        prepend += "#{@interp.args.keys[i]} = args[#{i}];\n"
      end
      type = args[0].schema_class
      Kernel::eval(prepend+interp.rules[type.name].body.gsub('\'','"'), binding)
    end

  end

  def interpret(obj, *args)
    send(@interp.action, obj, *args)
  end

end
