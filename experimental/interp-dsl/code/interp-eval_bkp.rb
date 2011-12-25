require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-type.rb'

class InterpreterBKP

  def initialize(interp)
    @interp = interp
    Kernel::eval(@interp.init.gsub('\'','"')) if !@interp.init.nil?
  end

  def interpret(obj, *args)
    type = obj.schema_class
    prepend = ""
    fields = {}
    type.fields.each do |f|
      fields[f.name] = f.type.Primitive? ? obj[f.name] : interpret(obj[f.name])
      prepend += "#{f.name} = fields[\"#{f.name}\"]\n"
    end
    Kernel::eval(prepend+@interp.rules[type.name].body.gsub('\'','"'), binding)
  end

end

=begin
interesting observations:

- side effects?
- sequencing in non-side effect-free exprs (eg print))
- no shared mutable state
- no arguments

=end
