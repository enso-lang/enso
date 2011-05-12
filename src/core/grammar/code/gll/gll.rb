#### pop when creating a node (like reduce)

require 'set'
require 'ostruct'

require 'core/grammar/code/gll/gss'
require 'core/grammar/code/gll/sppf'
require 'core/grammar/code/gll/scan'
require 'core/grammar/code/gll/grammar'

class Empty
  EMPTY_CLASS = OpenStruct.new
  EMPTY_CLASS.name = 'Empty'

  def schema_class
    EMPTY_CLASS
  end

  def to_s
    "<empty>"
  end

end

class Item
  ITEM_CLASS = OpenStruct.new
  ITEM_CLASS.name = 'Item'

  attr_reader :elements, :dot, :symbol

  def initialize(elements, dot, symbol)
    @elements = elements
    @dot = dot
    @symbol = symbol
    @hash = 17 * elements.hash + 23 * dot
  end

  def schema_class
    ITEM_CLASS
  end

  def current
    elements[dot]
  end

  def move
    puts "/* MOVING: #{dot + 1} (#{symbol}) */"
    Item.new(elements, dot + 1, symbol)
  end

  def at_end?
    dot == arity
  end

  def arity
    elements.length
  end

  def to_s
    "<#{elements}, #{dot}: #{symbol}>"
  end

  def ==(x)
    return true if self.equal?(x)
    return false unless x.is_a?(Item)
    elements == x.elements && dot == x.dot && symbol == x.symbol
  end

  def hash
    @hash
  end

end

class GLL
  include Scanner
  include Symbols

  def init_parser(grammar, top)
    @ci = 0
    @start = GSS.new(Item.new([grammar], 1, grammar), 0)
    @cu = @start
    @cn = nil
    @todo = []
    @done = {}
    @toPop = {}
  end

  def parse(grammar, source, top)
    init_scanner(grammar, source)
    init_parser(grammar, top)
    add(top)
    while !@todo.empty? do
      parser, @cu, @cn, @ci = @todo.shift
      #puts "Going to parse: #{parser}, cu = #{@cu}, cn = #{@cn}, ci = #{@ci}"
      recurse(parser)
    end
    puts "/* GSS: #{GSS.nodes.length} */"
    puts "/* Nodes: #{Node.nodes.length} */"
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
    #puts "Adding #{parser} (i = #{i}, u =  #{u}, w = #{w})"
    @done[i] ||= []
    conf = [parser, u, w]
    unless @done[i].include?(conf)
      @done[i] << conf
      @todo << [parser, u, w, i]
    end
  end

  def pop
    return if @cu == @start
    @toPop[@cu] ||= {}
    @toPop[@cu][@cn] ||= @cn
    cnt = @cu.parser
    @cu.edges.each do |w, gs|
      gs.each do |u|
        x = Node.new(cnt, w, @cn)
        #puts "Adding in pop"
        add(cnt, u, @ci, x)
      end
    end
  end

  def create(parser)
    w = @cn
    v = GSS.new(parser, @ci)
    if v.add_edge(w, @cu) then
      if @toPop[v] then
        @toPop[v].each_key do |z|
          x = Node.new(parser, w, z)
          add(parser, @cu, z.starts, z)
        end
      end
    end
    return v
  end

  def recurse(this, *args)
    #puts "Sending #{this.schema_class.name}"
    send(this.schema_class.name, this, *args)
  end

  def chain(this, nxt)
    @cu = create(nxt) if nxt
    continue(Item.new([this.arg], 0, this))
  end

  def continue(nxt)
    Item(nxt) if nxt
  end

  def terminal(pos, value, ws, nxt)
    cr = Leaf.new(@ci, pos, value, ws)
    @ci = pos
    if nxt then
      @cn = Node.new(nxt, @cn, cr)
      continue(nxt)
    end
  end
 

  def Item(this)
    puts "/* Parsing item: #{this} */"
    if this.at_end? then
      puts "/* Popping item: #{this} */"
      pop
    else
      recurse(this.current, this.move)
    end
  end


end


if __FILE__ == $0 then
  require 'core/grammar/code/gll/gamma2'
  #src = "b " * 10
  #gamma2 = Gamma2.grammar
  #GLL.new.parse(gamma2, src, gamma2.start)

#   src = "x + x + x"
#   exp = Exp.grammar
#   GLL.new.parse(exp, src, exp.start)

  src = "[x x x x]"
  lst = Lists.grammar
  GLL.new.parse(lst, src, lst.start)

  dot = ''
  Node.to_dot(dot)
  puts dot
end
  
