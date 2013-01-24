

require 'core/semantics/factories/combinators'
require 'core/system/utils/paths'

class Resolve
  include Factory

  def Const(sup)
    Class.new(sup) do
      attr_reader :value
      def resolve(it)
        value
      end
    end
  end

  def Anchor(sup)
    Class.new(sup) do 
      attr_reader :type
      def resolve(it)
        Paths.new([Current.new])
      end
    end
  end

  def Sub(sup)
    Class.new(sup) do 
      attr_reader :parent, :name, :key
      def resolve(it)
        p = parent ? parent.resolve(it) : Paths.new
        if key then
          p.field(name).key(key.resolve(it))
        else
          p.field(name)
        end
      end
    end
  end

  def It(sup) 
    Class.new(sup) do
      def resolve(it)
        it
      end
    end
  end
end
