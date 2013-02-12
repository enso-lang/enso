require 'core/semantics/code/interpreter'

# Creates a new interpreter from a block
# block will apply to all objects regardless of type
class Interpreter
  module AsInterp; end

  def self.do(operation, &block)
    newmod = AsInterp.clone
    newmod.operation(operation.to_sym)
    newmod.send(:define_method, operation) do |args={}, &block2| 
      block.call(@this, args, &block2)
    end
    newmod
  end
end
