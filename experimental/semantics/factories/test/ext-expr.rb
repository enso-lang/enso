
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/test/exprs'


class Memo
  include Factory

  def Add(sup)
    Class.new(sup) do
      def eval
        @memo ||= {}
        puts "Memo called"
        if @memo[self] then
          @memo[self]
        else
          @memo[self] = super
        end
      end
    end
  end
end

class Trace
  include Factory

  def Expr(sup)
    Class.new(sup) do 
      def eval
        puts "Enter"
        x = super
        puts "Exit"
        x
      end
    end
  end
end

class PrintConst #< Trace
  include Factory

  def Const(sup)
    Class.new(sup) do
      def eval
        puts "value = #{value}"
        super
      end
    end
  end
end

class Debug
  include Factory
  def Expr(sup)
    Class.new(sup) do
      def eval
        puts "DEBUG: #{render}"
        super
      end
    end
  end
end

class Count
  include Factory

  def State(sup)
    Class.new(sup) do
      @@count = 0
      def incr
        @@count += 1
      end
      def count
        @@count
      end
    end
  end

  def Expr(sup)
    Class.new(State(sup)) do
      def eval
        incr
        super
      end
    end
  end
end

if __FILE__ == $0 then
  Ex1 = Add.new(Const.new(1), Const.new(2))
  Ex2 = Add.new(Const.new(5), Ex1)

  puts "### Memo Add"
  MemoEx1 = FFold.new(Extend.new(Memo.new, Eval.new)).fold(Ex1)

  puts MemoEx1.eval

  puts "### Trace eval"
  TraceEx1 = FFold.new(Extend.new(Trace.new, Eval.new)).fold(Ex1)

  puts TraceEx1.eval


  puts "### Eval + Trace + Memo Add"

  MemoTraceEx1 = FFold.new(Extend.new(Memo.new, 
                                               Extend.new(Trace.new, Eval.new))).fold(Ex1)

  puts MemoTraceEx1.eval


  puts "### Eval + Trace + PrintConst" 

  PrintConstTraceEx1 = FFold.new(Extend.new(PrintConst.new,
                                              Extend.new(Trace.new, Eval.new))).fold(Ex1)
  puts PrintConstTraceEx1.eval


  puts "### Eval + Trace + PrintConst + Memo Add" 

  f = Extend.new(PrintConst.new, Extend.new(Trace.new, Eval.new))
  MemoPrintConstTraceEx1 = FFold.new(Extend.new(Memo.new, f)).fold(Ex1)
  puts MemoPrintConstTraceEx1.eval


  puts "### Debug using Render + Eval"
  DebugRenderEvalEx1 = FFold.new(Extend.new(Debug.new, Extend.new(Render.new, Eval.new))).fold(Ex1)
  puts DebugRenderEvalEx1.eval

  

  puts "### Count + Eval"
  CountEvalEx1 = FFold.new(Extend.new(Count.new, Eval.new)).fold(Ex2)
  puts CountEvalEx1.eval
  puts CountEvalEx1.count

end
