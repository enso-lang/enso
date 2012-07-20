
require 'core/expr/code/eval2'
require 'core/grammar/parse/path-eval'

module GrammarInterpreter
  include ExprEval
  include PathEval

  class Grammar
    attr_reader :start, :rules

    def start_item
      Item.new(start, [start.arg], 1)
    end
    
    def eval(gll)
      gll.add(start)
    end
    
    def literals
      rules.values.flat_map(&:literals)
    end
  end

  class Item
    attr_reader :expression, :elements, :dot

    def self.new(exp, elts, dot)
      @@items ||= {}
      key = [exp, elts, dot]
      @@items[key] ||= super(exp, elts, dot)
    end

    def initialize(exp, elts, dot)
      @expression = exp
      @elements = elts
      @dot = dot
    end

    def eval(gll, nxt)
      #puts "EVAL ITEM: #{expression} (dot = #{dot})"
      if dot == elements.length then
        gll.pop
      else
        nxt = Item.new(expression, elements, dot + 1)
        elements[dot].eval(gll, nxt)
      end
    end

  end

  class Pattern
    def literals
      []
    end
  end

  class Sequence < Pattern
    attr_reader :elements

    def eval(gll, nxt)
      item = Item.new(self, elements, 0)
      if elements.empty? then
        gll.create(nxt) if nxt # this is needed to make sure chaining
        # works correctly in case the leaf is empty; otherwise
        # we lose empty Creates which are needed to make "empty" objects.
        gll.empty_node(item, EPSILON)
        nxt.eval(gll, nil) if nxt
      else
        gll.create(nxt) if nxt
        item.eval(gll, nil)
      end
    end

    def literals
      elements.flat_map(&:literals)
    end

  end
  
  class Epsilon < Pattern
    def eval(gll, nxt)
      gll.empty_node(Item.new(self, [], 0), EPSILON)
      nxt.eval(gll, nil) if nxt
    end
  end

  EPSILON = Epsilon.new

  class NOP < Pattern
    def eval(gll, nxt)
      nxt.eval(gll, nil) if nxt
    end
  end

  class NoSpace < NOP; end
  class Break < NOP; end

  class Call < Pattern
    attr_reader :rule
    def eval(gll, nxt)
      rule.eval(gll, nxt)
    end
  end

  class Chained < Pattern
    attr_reader :arg
    def eval(gll, nxt)
      gll.create(nxt) if nxt
      gll.add(Item.new(self, [arg], 0))
    end

    def literals
      arg.literals
    end
  end

  class Rule < Chained
    attr_reader :name

    def eval(gll, nxt)
      #puts "EVAL RULE: #{name}"
      super(gll, nxt)
    end
  end

  class Create < Chained
    attr_reader :name
    def eval(gll, nxt)
      #puts "EVAL CREATE: #{name}"
      super(gll, nxt)
    end
  end

  class Field < Chained
    attr_reader :name
    def eval(gll, nxt)
      #puts "EVAL FIELD: #{name}"
      super(gll, nxt)
    end
  end

  class Alt < Pattern
    attr_reader :alts
    def eval(gll, nxt)
      gll.create(nxt) if nxt
      alts.each do |alt|
        gll.add(alt)
      end
    end

    def literals
      alts.flat_map(&:literals)
    end
  end

  class Terminal < Pattern
    def terminal(pos, value, ws, gll, nxt)
      cr = gll.leaf_node(pos, self, value, ws)
      if nxt then
        gll.item_node(nxt, cr)
        nxt.eval(gll, nil)
      end
    end
  end

  class Code < Terminal
    attr_reader :expr
    def eval(gll, nxt)
      terminal(gll.ci, expr, '', gll, nxt)
    end
  end

  class Lit < Terminal
    attr_reader :value
    def eval(gll, nxt)
      gll.with_literal(value) do |pos, ws|
        terminal(pos, value, ws, gll, nxt)
      end
    end

    def literals
      [value]
    end
  end

  class Ref < Terminal
    def eval(gll, nxt)
      gll.with_token('sym') do |pos, tk, ws|
        terminal(pos, tk, ws, gll, nxt)
      end
    end
  end

  class Value < Terminal
    attr_reader :kind
    def eval(gll, nxt)
      gll.with_token(kind) do |pos, tk, ws|
        terminal(pos, tk, ws, gll, nxt)
      end
    end
  end

  class Regular < Pattern
    attr_reader :many, :optional, :sep, :arg

    # all args optional, because of fold
    def initialize(arg = nil, optional = nil, many = nil, sep = nil)
      @arg = arg
      @optional = optional
      @many = many
      @sep = sep
    end

    def eval(gll, nxt)
      #puts "EVAL REGULAR: many = #{many}, optional = #{optional}, sep = #{sep.inspect}"
      gll.create(nxt) if nxt
      if !many && optional then
        gll.add(EPSILON)
        gll.add(arg)
      elsif many && !optional && !sep then
        gll.add(arg)
        gll.add(Item.new(self, [arg, self], 0))
      elsif many && optional && !sep then
        gll.add(EPSILON)
        gll.add(Item.new(self, [arg, self], 0))
      elsif many && !optional && sep then
        gll.add(arg) 
        gll.add(Item.new(self, [arg, sep, self], 0))
      elsif many && optional && sep then
        gll.add(EPSILON)
        @iter ||= Regular.new(arg, false, true, sep)
        gll.add(@iter)
      else
        raise "Invalid regular: #{self}"
      end
    end

    def literals
      arg.literals
    end
  end

end
