
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/obj-fold'
require 'set'

class Stm
  attr_accessor :parent
end

class While < Stm
  attr_reader :exp, :body
  def self.fields; [:body] end

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

  def self.fields; [:body1, :body2] end

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
  def self.fields; [] end

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
  def self.fields; [] end

  def initialize(exp)
    @exp = exp
  end

  def to_s
    "return_#{object_id}"
  end
end

class Block < Stm
  attr_reader :stms
  def self.fields; [:stms] end

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
      def succ; following end
      def following; parent.follow(self) end
      def follow(kid); [] end
    end
  end
  
  def If(sup)
    Class.new(sup) do
      def succ; [body1, body2] end
    end
  end

  def While(sup)
    Class.new(sup) do
      def succ; following | [body] end
      def follow(kid); [self] end
    end
  end

  def Return(sup)
    Class.new(sup) do
      def succ; [] end
    end
  end

  def Block(sup)
    Class.new(sup) do
      def succ; [stms.first] end

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
    Class.new(sup) do
      def uses; Set.new end
      def defines; Set.new end
      def inn; uses | (out - defines) end
      def out; succ.inject(Set.new) { |cur, x| cur | x.inn } end
    end
  end

  def Assign(sup)
    Class.new(sup) do
      def defines; Set.new([var]) end
      def uses; Set.new([exp]) end
    end
  end

  def While(sup)
    Class.new(sup) do
      def uses; Set.new([exp]) end
    end
  end

  def Return(sup)
    Class.new(sup) do
      def uses; Set.new([exp]) end
    end
  end

  def If(sup)
    Class.new(sup) do
      def uses; Set.new([exp]) end
    end
  end
end

class Visit
  include Factory

  def Stm(sup)
    Class.new(sup) do
      def visit(&block)
        yield self, inn, out
      end
    end
  end

  def While(sup)
    Class.new(Stm(sup)) do
      def visit(&block)
        super(&block)
        body.visit(&block)
      end
    end
  end

  def If(sup)
    Class.new(Stm(sup)) do
      def visit(&block)
        super(&block)
        body1.visit(&block)
        body2.visit(&block)
      end
    end
  end

  def Block(sup)
    Class.new(Stm(sup)) do
      def visit(&block)
        stms.each { |x| 
          x.visit(&block)
        }
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
    x.succ.each do |t|
      puts "#{x} -> #{t}"
      if !done.include?(t)
        todo |= [t]
      end
    end
  end

  puts "### Liveness"
  f = TopDown.new(:visit, [:out, :inn]) < 
    Circular.new({out: "Set.new", inn: "Set.new"}) < 
    Liveness.new < 
    CFlow.new
  live = FFold.new(f).fold(prog)
  
  live.visit do |n, i, o|
   puts "#{n}: in = {#{i.to_a.sort.join(', ')}}; out = {#{o.to_a.sort.join(', ')}}"
  end

end
