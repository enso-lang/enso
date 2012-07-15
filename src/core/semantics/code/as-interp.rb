require 'core/semantics/code/interpreter'

# Creates a new interpreter from a block
# block will apply to all objects regardless of type
class Interpreter
  module AsInterp; end

  def self.do(operation, &block)
    newmod = AsInterp.clone
    newmod.send(:define_method, "#{operation}_?") do |type, fields, args={}| 
      block.call(@this)
    end
    newmod.operation(operation.to_sym)
    newmod
  end
end
