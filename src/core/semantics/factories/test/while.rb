
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/obj-fold'


class Stm
  attr_accessor :parent
end

class While < Stm
  attr_reader :exp, :body
  def initialize(exp, body)
    @exp = exp
    @body = body
  end

  def to_s
    "while_#{object_id}"
  end
end

class If < Stm
  attr_reader :exp, :body1, :body2
  def initialize(exp, body1, body2)
    @exp = exp
    @body1 = body1
    @body2 = body2
  end

  def to_s
    "if_#{object_id}"
  end
end

class Assign < Stm
  attr_reader :var, :exp
  def initialize(var, exp)
    @var = var
    @exp = exp
  end

  def to_s
    "assign_#{object_id}"
  end
end

class Return < Stm
  attr_reader :exp
  def initialize(exp)
    @exp = exp
  end

  def to_s
    "return_#{object_id}"
  end
end

class Block < Stm
  attr_reader :stms
  def initialize(stms)
    @stms = stms
  end

  def to_s
    "block_#{object_id}"
  end
end


class CFlow
  include Factory

  def Stm(sup)
    Class.new(sup) do
      def succ
        following.map { |x| [self, x] }
      end

      def following
        parent.follow(self)
      end

      def follow(kid)
        []
      end
    end
  end
  
  def If(sup)
    Class.new(sup) do
      def succ
        [[self, body1], [self, body2]]
      end
    end
  end

  def While(sup)
    Class.new(sup) do
      def succ
        (following | [body]).map do |x|
          [self, x]
        end
      end

      def follow(kid)
        [self]
      end
    end
  end

  def Return(sup)
    Class.new(sup) do
      def succ
        []
      end
    end
  end

  def Block(sup)
    Class.new(sup) do
      def succ
        [[self, stms.first]]
      end

      def follow(kid)
        if kid == stms.last then
          following
        else
          i = stms.index(kid)
          [stms[i + 1]]
        end
      end
    end
    
  end
end



class Liveness
  include Factory
  
  def Stm(sup)
    def uses
      Set.new
    end
    
    def defines
      Set.new
    end

    def inn
      uses + out - defines
    end

    def out
      # ???
      succ.flat_map(inn)
    end
  end

  def Assign(sup)
    Class.new(sup) do
      def defines
        var
      end
    end
  end

  def While(sup)
    Class.new(sup) do
      def uses
        Set.new([exp])
      end

      def succ
        following + Set.new([body])
      end

      def following
        Set.new([self])
      end
    end
  end

  def Block(sup)
    Class.new(sup) do
      def succ
        [stms.first]
      end
    end
  end

end


if __FILE__ == $0 then
  puts "### CFlow"

  prog = Block.new([
                    Assign.new(:y, :v),
                    Assign.new(:z, :y),
                    Assign.new(:x, :v),
                    While.new(:x, Block.new([
                                             Assign.new(:x, :w),
                                             Assign.new(:x, :v)
                                            ])),
                    Return.new(:x)])
  
  prog.stms[0].parent = prog
  prog.stms[1].parent = prog
  prog.stms[2].parent = prog
  prog.stms[3].parent = prog
  prog.stms[4].parent = prog
  prog.stms[3].body.parent = prog.stms[3]
  prog.stms[3].body.stms[0].parent = prog.stms[3].body
  prog.stms[3].body.stms[1].parent = prog.stms[3].body
  
  cflow = FFold.new(CFlow.new).fold(prog)
  done = []
  todo = [cflow]
  while !todo.empty?
    x = todo.shift
    done << x
    x.succ.each do |f, t|
      puts "#{f} -> #{t}"
      if !done.include?(f)
        todo |= [f]
      end
      if !done.include?(t)
        todo |= [t]
      end
    end
  end
end
