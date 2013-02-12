


class Factory
  class << self
    def supplies?(sym)
      @mixins ||= {}
      @mixins.has_key?(sym)
    end

    def enhance(cls, me)
      @mixins ||= {}
      sym = cls.name.to_sym
      if sym == :Object then
        me
      elsif supplies?(sym) then
        me.class_eval(&@mixins[sym])
        return me
      else
        enhance(cls.superclass, me)
      end
    end

    def to(sym, &block)
      @mixins ||= {}
      @mixins[sym] = block
    end
  end
end


class Combinator
  def initialize(f1, f2)
    @f1 = f1
    @f2 = f2
  end

  def supplies?(cls)
    @f1.supplies?(cls) || @f2.supplies?(cls)
  end
end


class Merge < Combinator
  def enhance(cls, me)
    @f1.enhance(cls, me)
    @f2.enhance(cls, me)
    return me
  end

  def to_sym
    "#{@f1} + #{@f2}"
  end
end    

class Refine < Combinator
  def enhance(cls, me)
    @f1.enhance(cls, Class.new(@f2.enhance(cls, me)))
  end

  def to_s
    "#{@f1} < #{@f2}"
  end
end


class Expr
  @@cache = {}
end

class Add < Expr
  attr_reader :lhs, :rhs
  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end

  def fold(fact)
    # first do kids
    l = lhs.fold(fact)
    r = rhs.fold(fact)

    if !@@cache[[self.class, fact]] then
      puts "creating class for #{self.class}"
      @@cache[[self.class, fact]] = fact.enhance(self.class, Class.new(self.class))
    end

    # return object
    return @@cache[[self.class, fact]].new(l, r)
  end

  def lazy_fold(fact)
    cls = Class.new do
      def initialize(this, fact, memo)
        @this = this
        @fact = fact
        @memo = memo
      end
    end
    fact.enhance(self.class, cls)
    cls.new(self, fact, {})
  end
end


class Wrap
  def initialize(this, fact, memo)
    @this = this
    @fact = fact
    @memo = memo
  end

end



class Const < Expr
  attr_reader :value
  def initialize(value)
    @value = value
  end

  def fold(fact)
    if !@@cache[[self.class, fact]] then
      puts "creating class for #{self.class}"
      @@cache[[self.class, fact]] = fact.enhance(self.class, Class.new(self.class))
    end
    @@cache[[self.class, fact]].new(value)
  end


  def lazy_fold(fact)
    fold(fact)
  end
      

end

class Eval < Factory
  to :Add do
    def eval
      lhs.eval + rhs.eval
    end
  end

  to :Const do
    def eval
      value
    end
  end
end

class Render < Factory
  to :Add do
    def render
      "#{lhs.render} + #{rhs.render}"
    end
  end
  
  to :Const do
    def render
      value.to_s
    end
  end
end

class Trace < Factory
  to :Expr do
    def eval
      puts "enter: #{render}"
      x = super
      puts "exit"
      x
    end
  end
end

class TraceAdd < Factory
  to :Add do
    def eval
      puts "ADD: #{render}"
      x = super
      puts "EXIT"
      x
    end
  end
end



if __FILE__ == $0 then
  ex1 = Add.new(Const.new(1), Const.new(2))
  ex2 = Add.new(Const.new(5), ex1)

  evalEx2 = ex2.fold(Eval)

  puts evalEx2.eval

  puts "#### Eval + Render"
  evalRenderEx2 = ex2.fold(Merge.new(Eval, Render))
  
  puts evalRenderEx2.render
  puts evalRenderEx2.eval
  
  puts "#### Trace < (Eval + Render)"

  evalRenderTraceEx2 = ex2.fold(Refine.new(Trace, Merge.new(Eval, Render)))
  
  puts evalRenderTraceEx2.eval

  puts "#### (Trace + TraceAdd) < (Eval + Render)"

  evalRenderTraceAddEx2 = ex2.fold(Refine.new(Merge.new(Trace, TraceAdd), Merge.new(Eval, Render)))
  
  puts evalRenderTraceAddEx2.eval
  
  puts "#### TraceAdd < Trace < (Eval + Render)"

  evalRenderTraceAddEx2 = ex2.fold(Refine.new(Refine.new(TraceAdd, Trace), Merge.new(Eval, Render)))
  
  puts evalRenderTraceAddEx2.eval
  

  exit!


  puts "### Render"
  renderEx1 = FFold.new(Render.new).fold(Ex1)
  
  puts RenderEx1.render
end


