
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/obj-fold'

class Grammar
  attr_reader :start, :rules
  def initialize(start, rules)
    @start = start
    @rules = rules
  end
end

class Rule
  attr_reader :name, :alts
  def initialize(name, alts)
    @name = name
    @alts = alts
  end
end

class Alt
  attr_reader :elts
  def initialize(elts)
    @elts = elts
  end
end

class Sym
end

class NonTerminal < Sym
  attr_reader :name
  def initialize(name)
    @name = name
  end
end

class Terminal < Sym
  attr_reader :value
  def initialize(value)
    @value = value
  end
end

class Nullable
  include Factory
  def FindRule(sup)
    Class.new(sup) do 
      def find_rule(name)
        @@grammar.rules.find {|r| r.name == name}
      end
    end
  end
        
  def Grammar(sup)
    Class.new(FindRule(sup)) do
      def nullable?(tbl)
        @@grammar = self
        find_rule(start.name).nullable?(tbl)
      end
    end
  end
  
  def Rule(sup)
    Class.new(sup) do
      def nullable?(tbl)
        alts.inject(false) { |cur, alt| cur | alt.nullable?(tbl) }
      end
    end
  end

  def Alt(sup)
    Class.new(sup) do
      def nullable?(tbl)
        elts.inject(true){ |cur, elt| cur & elt.nullable?(tbl) }
      end
    end
  end

  def Terminal(sup)
    Class.new(sup) do 
      def nullable?(tbl)
        false
      end
    end
  end

  def NonTerminal(sup)
    Class.new(FindRule(sup)) do
      def nullable?(tbl)
        x = find_rule(name).nullable?(tbl)
        tbl[name] = x
      end
    end
  end
end

        

      


Arith = Grammar.new(NonTerminal.new(:Stat), 
                [
                 Rule.new(:Exp, [
                                 Alt.new([Terminal.new(:Var)]),
                                 Alt.new([NonTerminal.new(:Exp),
                                          Terminal.new("+"),
                                          NonTerminal.new(:Exp)])]),
                 Rule.new(:Stat, [Alt.new([NonTerminal.new(:Exp),
                                           Terminal.new(";")]),
                                  Alt.new([Terminal.new("{"),
                                           NonTerminal.new(:Stats),
                                           Terminal.new("}")])]),
                 Rule.new(:Stats, [Alt.new([]),
                                   Alt.new([NonTerminal.new(:Stat),
                                            NonTerminal.new(:Stats)])])
                ])


#FixNullable = RExtend.new(Fixpoint.new(:nullable?, true), Nullable.new, 
#                          {:NonTerminal => :Node})
#FixNullable = Extend.new(Rename.new(Fixpoint.new(:nullable?, true),
#                                    {:NonTerminal => :Node}),
#                          Nullable.new)

FixNullable = Extend.new(Restrict.new(Circular.new({:nullable? => false}),
                                  [:NonTerminal]), Nullable.new)

ArithNullableFix = FFold.new(FixNullable).fold(Arith)
tbl = {}
puts ArithNullableFix.nullable?(tbl)
p tbl      
