
require 'core/schema/code/factory'
require 'core/system/library/schema'

module GLLFactory

  def self.new
    GLLFactoryClass.new
  end

  module GLLClasses

    class EnsoBase
      def equals(o)
        self == o
      end      
    end

    class Item < EnsoBase
      attr_reader :expression, :elements, :dot
      def initialize(exp, elts, dot)
        @expression = exp
        @elements = elts
        @dot = dot
      end
      
      def name
        'Item'
      end

      def schema_class
        self
      end
    end

    class GSS < EnsoBase
      attr_reader :item, :pos, :edges
      def initialize(item, pos)
        @item = item
        @pos = pos
        @edges = []
      end
    end

    class Edge < EnsoBase
      attr_reader :sppf, :target
      def initialize(sppf, target)
        @sppf = sppf
        @target = target
      end
    end

    class SPPF < EnsoBase
      def Node?; false end
      def Leaf?; false end
      def Empty?; false end
      def Pack?; false end
    end

    class Base < SPPF
      attr_reader :starts, :ends, :type, :origin
      def initialize(starts, ends, type, origin)
        @starts = starts
        @ends = ends
        @type = type
        @origin = origin
      end

      def kids; [] end
    end


    class Node < Base
      attr_reader :kids
      def initialize(starts, ends, type, origin)
        super(starts, ends, type, origin)
        @kids = []
      end

      def Node?; true end
    end

    class Leaf < Base
      attr_reader :value, :ws
      def initialize(starts, ends, type, origin, value, ws)
        super(starts, ends, type, origin)
        @value = value
        @ws = ws
      end

      def Leaf?; true end
    end

    class Empty < Base
      def Empty?; true end
    end

    class Pack < SPPF
      attr_reader :type, :pivot, :left, :right
      def initialize(parent, type, pivot, left, right)
        @type = type
        @pivot = pivot
        @left = left
        @right = right
      end

      def kids
        [left,right].compact
      end

      def Pack?; true end
    end

  end

  class GLLFactoryClass

    # This factory mimicks SharingFactor::new(<the grammar schema>)
    # with to make shared Items, GSS nodes and SPPF nodes.

    include GLLClasses

    def initialize
      @memo = {}
    end

    def Item(exp, elts, dot)
      make(Item, exp, elts, dot)
    end

    def GSS(item, pos)
      make(GSS, item, pos)
    end

    def Edge(sppf, target)
      make(Edge, sppf, target)
    end

    def Node(starts, ends, type, origin)
      make(Node, starts, ends, type, origin)
    end

    def Leaf(starts, ends, type, origin, value, ws)
      make(Leaf, starts, ends, type, origin, value, ws)
    end

    def Empty(starts, ends, type, origin)
      make(Empty, starts, ends, type, origin)
    end

    def Pack(parent, type, pivot, left, right)
      make(Pack, parent, type, pivot, left, right)
    end


    def _objects_for(klass)
      @memo.values.select do |x|
        # a little brittle maybe
        x.class.name.end_with?(klass.name)
      end
    end

    private

    def make(klass, *args)
      if !@memo.has_key?(args) then
        @memo[args] = klass.new(*args)
      end
      @memo[args]
    end

  end
end
