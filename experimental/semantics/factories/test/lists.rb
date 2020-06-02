
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/obj-fold'


=begin

http://www.haskell.org/haskellwiki/The_Monad.Reader/Issue4/Why_Attribute_Grammars_Matter 

diff :: [Float] -> [Float]
diff xs = map (\x -> x - (avg xs)) xs
 
avg :: [Float] -> Float
avg xs = sum xs / genericLength xs
=end

class List
end

class Nil < List
  def to_s
    "()"
  end
end

class Cons < List
  attr_reader :head, :tail

  def initialize(head, tail)
    super()
    @head = head
    @tail = tail
  end

  def to_s
    "(#{head} . #{tail})"
  end
end

class Length
  include Factory
  
  def Nil(sup)
    Class.new(sup) do
      def size
        0
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do 
      def size
        1 + tail.size
      end
    end
  end
end


class Sum
  include Factory
  
  def Nil(sup)
    Class.new(sup) do
      def sum
        0
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do 
      def sum
        head + tail.sum
      end
    end
  end
end


class Avg
  include Factory
  
  def Nil(sup)
    Class.new(sup) do
      def avg
        0.0
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do 
      def avg
        sum / size
      end
    end
  end

end

class Diff 
  include Factory

  def Nil(sup)
    Class.new(sup) do
      def diff(a)
        Nil.new
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do 
      def diff(a = avg)
        Cons.new(head - a, tail.diff(a))
      end
    end
  end
end

class LengthSum 
  include Factory

  def Nil(sup)
    Class.new(sup) do
      def size_sum
        [0, 0.0]
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do 
      def size_sum
        l, s = tail.size_sum
        [l + 1, s + head]
      end
    end
  end
end

class LengthSumAvg 
  include Factory

  def Nil(sup)
    Class.new(sup) do
      def size_sum
        [0, 0.0, lambda { |avg| Nil.new }]
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do 
      def size_sum
        l, s, rs = tail.size_sum
        [l + 1, s + head, lambda { |avg| Cons.new(head - avg, rs.call(avg)) } ]
      end
    end
  end
end

class Incr
  include Factory

  def Nil(sup)
    Class.new(sup) do 
      def incr
        []
      end
    end
  end

  def Cons(sup)
    Class.new(sup) do
      def incr
        [head + 1, tail.incr]
      end
    end
  end
end


if __FILE__ == $0 then
  lst = Cons.new(1.0, Cons.new(2.0, Cons.new(5.0, Nil.new)))
  
  diff = Extend.new(Diff.new, Extend.new(Avg.new, 
                                         Extend.new(Sum.new, Length.new)))

  diff = Extend.new(Count.new([:diff, :size, :avg, :sum]), diff)

  evlst = FFold.new(diff).fold(lst)

  puts "### Naive diff"
  x = evlst.diff
  puts x
  puts evlst.count.inspect

  puts "### Mapping incr"

  evlst = FFold.new(Extend.new(Map.new(:incr), Incr.new)).fold(lst)
  puts evlst.incr

  puts "### Lengthsum"

  evlst = FFold.new(LengthSum.new).fold(lst)
  puts evlst.size_sum

  puts "### Lengthsum avg"

  evlst = FFold.new(Extend.new(Count.new([:size_sum]), 
                               LengthSumAvg.new)).fold(lst)
  puts evlst.count.clear

  l, s, rs = evlst.size_sum
  puts "Length: #{l}"
  puts "Sum: #{s}"
  puts "Avg: #{rs}"
  puts "List: #{rs.call(s / l)}"
  puts "Profile: #{evlst.count.inspect}"
end
