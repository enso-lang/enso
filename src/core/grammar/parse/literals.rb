
require 'core/semantics/factories/combinators'

class Literals
  include Factory

  def Grammar(sup)
    Class.new(sup) do
      attr_reader :start
      def literals
        start.literals
      end
    end
  end

  def Pattern(sup)
    Class.new(sup) do
      def literals; [] end
    end
  end

  def Sequence(sup)
    Class.new(sup) do
      attr_reader :elements
      def literals
        elements.flat_map(&:literals)
      end
    end
  end

  def Chained(sup)
    Class.new(sup) do
      attr_reader :name, :arg
      def literals
        arg.literals
      end
    end
  end

  def Create(sup)
    Class.new(Chained(sup))
  end

  def Field(sup)
    Class.new(Chained(sup))
  end

  def Rule(sup)
    Class.new(Chained(sup))
  end

  def Call(sup)
    Class.new(sup) do
      attr_reader :rule
      def literals
        rule.literals
      end
    end
  end

  def Alt(sup)
    Class.new(sup) do
      attr_reader :alts
      def literals
        alts.flat_map(&:literals)
      end
    end
  end

  def Lit(sup)
    Class.new(sup) do
      attr_reader :value
      def literals
        [value]
      end
    end
  end

  def Regular(sup)
    Class.new(sup) do
      attr_reader :arg, :sep
      def literals
        arg.literals + (sep ? sep.literals : [])
      end
    end
  end
end


  
   
