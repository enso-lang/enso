
require 'pp'
require 'core/semantics/factories/combinators'

class Parse
  include Factory

  # Helper classes
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
    
    def parse(gll, nxt)
      if dot == elements.length then
        gll.pop
      else
        nxt = Item.new(expression, elements, dot + 1)
        elements[dot].parse(gll, nxt)
      end
    end

    # Unfortunate, but I can't think of another solution right now.
    def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
      sppf.build_kids(owner, accu, field, fixes, paths, fact, orgs)
    end
  end

  class Epsilon
    def parse(gll, nxt)
      gll.empty_node(Item.new(self, [], 0), EPSILON)
      nxt.parse(gll, nil) if nxt
    end

    def build_spine(sppf, owner, accu, field, fixes, paths, fact, orgs)
    end
  end

  EPSILON = Epsilon.new

  def Grammar(sup)
    Class.new(sup) do
      attr_reader :start
      def start_item
        Item.new(start, [start.arg], 1)
      end
      
      def parse(gll)
        gll.add(start)
      end
    end
  end


  def Sequence(sup)
    Class.new(sup) do
      attr_reader :elements
      def parse(gll, nxt)
        item = Item.new(self, elements, 0)
        if elements.empty? then
          gll.create(nxt) if nxt # this is needed to make sure chaining
          # works correctly in case the leaf is empty; otherwise
          # we lose empty Creates which are needed to make "empty" objects.
          gll.empty_node(item, EPSILON)
          nxt.parse(gll, nil) if nxt
        else
          gll.create(nxt) if nxt
          item.parse(gll, nil)
        end
      end
    end
  end
  

  def NoSpace(sup)
    Class.new(sup) do
      def parse(gll, nxt)
        nxt.parse(gll, nil) if nxt
      end
    end
  end

  def Break(sup)
    Class.new(sup) do
      def parse(gll, nxt)
        nxt.parse(gll, nil) if nxt
      end
    end
  end

  def Call(sup)
    Class.new(sup) do
      attr_reader :rule
      def parse(gll, nxt)
        rule.parse(gll, nxt)
      end
    end
  end

  def Chained(sup)
    Class.new(sup) do
      attr_reader :arg
      def parse(gll, nxt)
        gll.create(nxt) if nxt
        gll.add(Item.new(self, [arg], 0))
      end
    end
  end

  def Rule(sup)
    Class.new(Chained(sup))
  end

  def Create(sup)
    Class.new(Chained(sup))
  end

  def Field(sup)
    Class.new(Chained(sup))
  end

  def Alt(sup)
    Class.new(sup) do
      attr_reader :alts
      def parse(gll, nxt)
        gll.create(nxt) if nxt
        alts.each do |alt|
          gll.add(alt)
        end
      end
    end
  end

  def Terminal(sup)
    Class.new(sup) do
      def parse(pos, value, ws, gll, nxt)
        cr = gll.leaf_node(pos, self, value, ws)
        if nxt then
          gll.item_node(nxt, cr)
          nxt.parse(gll, nil)
        end
      end
    end
  end

  def Code(sup)
    Class.new(Terminal(sup)) do
      attr_reader :expr
      def parse(gll, nxt)
        super(gll.ci, expr, '', gll, nxt)
      end
    end
  end

  def Lit(sup)
    Class.new(Terminal(sup)) do
      attr_reader :value
      def parse(gll, nxt)
        pos, ws = gll.scan_literal(value)
        if pos then
          super(pos, value, ws, gll, nxt)
        end
        # NB:
        # super from singleton method that is defined to multiple classes is
        # not supported; this will be fixed in 1.9.3 or later (NotImplementedError)
        # gll.with_literal(value) do |pos, ws|
        #   super(pos, value, ws, gll, nxt)
        # end
      end
    end
  end

  def Ref(sup)
    Class.new(Terminal(sup)) do
      def parse(gll, nxt)
        pos, tk, ws = gll.scan_kind('sym')
        if pos then
          super(pos, tk, ws, gll, nxt)
        end

        # gll.with_token('sym') do |pos, tk, ws|
        #   super(pos, tk, ws, gll, nxt)
        # end
      end
    end
  end

  def Value(sup)
    Class.new(Terminal(sup)) do
      attr_reader :kind
      def parse(gll, nxt)
        pos, tk, ws = gll.scan_kind(kind)
        if pos then
          super(pos, tk, ws, gll, nxt)
        end
        # gll.with_token(kind) do |pos, tk, ws|
        #   super(pos, tk, ws, gll, nxt)
        # end
      end
    end
  end

  def Regular(sup)
    Class.new(sup) do
      attr_reader :arg, :optional, :many, :sep

      # all args optional, because of fold
      def initialize(arg = nil, optional = nil, many = nil, sep = nil)
        @arg = arg
        @optional = optional
        @many = many
        @sep = sep
      end

      def parse(gll, nxt)
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
    end
  end
end
