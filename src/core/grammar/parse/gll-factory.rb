
require 'core/schema/code/factory'
require 'core/system/library/schema'

module GLLFactory

  def self.new
    GLLFactoryClass.new
  end

  module GLLClasses
    class SchemaClass
      attr_reader :name
      def initialize(name)
        @name = name
      end

    end

    class EnsoBase
      attr_reader :schema_class
      def initialize(c)
        @schema_class = SchemaClass.new(c)
      end

      def equals(o)
        self == o
      end      
    end

    class GSS < EnsoBase
      attr_reader :item, :pos, :edges
      def initialize(item, pos)
        @item = item
        @pos = pos
        @edges = []
      end

      def to_s
        "gss(#{item}, #{pos})"
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
      def is_a?("Node"); false end
      def is_a?("Leaf"); false end
      def is_a?("Empty"); false end
      def is_a?("Pack"); false end
    end

    class Base < SPPF
      attr_reader :starts, :ends, :type, :origin
      def initialize(cls, starts, ends, type, origin)
        super(cls)
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
        super('Node', starts, ends, type, origin)
        @kids = []
      end 

      def is_a?("Node"); true end

      def to_s
        t = type.is_a?("Call") ? "call(#{type.rule.name})" : type.inspect
        "Node(#{starts}, #{ends}, #{t}: #{kids.join(', ')})"
      end
    end

    class Leaf < Base
      attr_reader :value, :ws
      def initialize(starts, ends, type, origin, value)
        super('Leaf', starts, ends, type, origin)
        @value = value
      end

      def is_a?("Leaf"); true end

      def to_s
        "Leaf(#{starts}, #{ends}, #{type}, '#{value}')"
      end
    end

    class Empty < Base
      def is_a?("Empty"); true end
      def to_s
        "()"
      end
    end

    class Pack < SPPF
      attr_reader :type, :pivot, :left, :right, :parent
      def initialize(parent, type, pivot, left, right)
        super('Pack')
        @parent = parent
        @type = type
        @pivot = pivot
        @left = left
        @right = right
      end

      def kids
        [left,right].compact
      end

      def is_a?("Pack"); true end

      def to_s
        "pack(#{type}, #{pivot})"
      end
    end

  end

  class GLLFactoryClass

    # This factory mimicks SharingFactor::new(<the grammar schema>)
    # with to make shared Items, GSS nodes and SPPF nodes.

    include GLLClasses

    def initialize
      @memo = {}
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

    def Leaf(starts, ends, type, origin, value)
      make(Leaf, starts, ends, type, origin, value)
    end

    def Pack(parent, type, pivot, left, right)
      make(Pack, parent, type, pivot, left, right)
    end


    def _objects_for(klass_name)
      @memo.values.select do |x|
        # ouch, brittle.
        x.class.name.end_with?(klass_name)
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
