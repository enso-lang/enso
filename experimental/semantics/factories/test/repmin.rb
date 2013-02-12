
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/obj-fold'

class Node
  attr_accessor :parent
end

class Pair < Node
  attr_reader :l, :r
  def initialize(l, r)
    @l = l
    @r = r
  end

  def to_s
    "(#{l}, #{r})"
  end
end


class Leaf < Node
  attr_reader :n
  def initialize(n)
    @n = n
  end
  
  def to_s
    n.to_s
  end
end

class RepMin
  include Factory
  def Pair(sup)
    Class.new(sup) do
      def locmin
        l.locmin < r.locmin ? l.locmin : r.locmin
      end
      
      def globmin
        parent.nil? ? locmin : parent.globmin
      end
      
      def repmin
        Pair.new(l.repmin, r.repmin)
      end
    end
  end
  
  def Leaf(sup)
    Class.new(sup) do
      def locmin
        n
      end
      
      def globmin
        parent.globmin
      end
      
      def repmin 
        Leaf.new(globmin)
      end
    end
  end
end


if __FILE__ == $0 then
  x = Pair.new(Leaf.new(3), Pair.new(Leaf.new(1), Leaf.new(10)))
  x.l.parent = x
  x.r.parent = x
  x.r.l.parent = x.r
  x.r.r.parent = x.r

  puts "#### Naive Repmin"

  f = RepMin.new
  f = Extend.new(Count.new([:locmin, :repmin, :globmin]), f)
  int = FFold.new(f).fold(x)
  puts int.globmin
  puts int.repmin
  puts "COUNT = #{int.count.inspect}"


  puts "#### Memo Repmin"

  f = RepMin.new
  f = Extend.new(Memo.new([:locmin, :repmin, :globmin]), f)
  f = Extend.new(Count.new([:locmin, :repmin, :globmin]), f)
  int = FFold.new(f).fold(x)
  int.count.clear
  puts int.globmin
  puts int.repmin
  puts "COUNT = #{int.count.inspect}"
  
  
end
