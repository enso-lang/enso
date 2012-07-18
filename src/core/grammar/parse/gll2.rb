
require 'core/grammar/parse/gss'
require 'core/grammar/tools/todot'
require 'core/grammar/parse/sppf'
require 'core/grammar/parse/eval2'
require 'core/schema/tools/print'

class GLL2
  attr_reader :ci

  def initialize(grammar)
    @grammar = grammar
    init_keywords(grammar)
  end

  def parse(source, filename = '-')
    @scanner = StringScanner.new(source)

    @todo = []
    @done = {}
    @toPop = {}

    # TODO: move these tables to here
    Node.nodes.clear
    GSS.nodes.clear

    ws, @start_pos = skip_ws
    @ci = @start_pos
    @cn = nil

    @cu = GSS.new(@grammar.start_item, 0)

    @grammar.eval(self)
    while !@todo.empty? do
      parser, @cu, @cn, @ci = @todo.shift
      parser.eval(self, nil)
    end
    result(source, filename, @grammar.start)
  end

  def result(source, filename, top)
    r = Node.nodes.values.find do |n|
      top_node?(n, source, top)
    end
    return r if r
    loc = Origins.new(source, filename).str(@ci)
    #Print.print(@cu.item)
    raise "Parse error at #{loc}:\n'#{source[@ci,50]}...'" 
  end
  
  def top_node?(node, source, top)
    node.is_a?(Node) &&
      node.starts == @start_pos && 
      node.ends == source.length  &&
      node.type == top
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
    @done[i] ||= {}
    conf = [parser, u, w]
    unless @done[i][conf]
      @done[i][conf] = true
      @todo << [parser, u, w, i]
    end
  end

  def pop
    return if @cu == @start
    @toPop[@cu] ||= {}
    @toPop[@cu][@cn] ||= @cn
    cnt = @cu.item
    @cu.edges.each do |w, gs|
      gs.each do |u|
        x = Node.new(cnt, w, @cn)
        add(cnt, u, @ci, x)
      end
    end
  end

  def create(item)
    w = @cn
    v = GSS.new(item, @ci)
    if v.add_edge(w, @cu) then
      if @toPop[v] then
        @toPop[v].each_key do |z|
          x = Node.new(item, w, z)
          add(item, @cu, z.ends, x)
        end
      end
    end
    @cu = v
  end

  def empty_node(item, eps)
    cr = Empty.new(@ci, eps)
    item_node(item, cr)
    pop
  end

  def item_node(item, cr)
    @cn = Node.new(item, @cn, cr)
  end

  def leaf_node(pos, type, value, ws)
    # NB: pos includes the ws that has been matched
    # so subtract the length of ws from pos.
    cr = Leaf.new(@ci, pos - ws.length, type, value, ws)
    @ci = pos
    return cr
  end


  SYMBOL = "[\\\\]?[a-zA-Z_][a-zA-Z_0-9]*"

  TOKENS =  {
    sym: Regexp.new(SYMBOL),
    int: /[-+]?[0-9]+(?![.][0-9]+)/,
    str: Regexp.new("\"(\\\\.|[^\"])*\"".encode('UTF-8')),
    real: /[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?/
  }
  
  LAYOUT = /(\s*(\/\/[^\n]*\n)?)*/


  def with_token(kind)
    @scanner.pos = @ci
    tk, kind = scan_token(kind)
    if tk then
      # keywords are reserved
      return if @keywords.include?(tk)
      ws, pos = skip_ws
      yield pos, unescape(tk, kind), ws 
    end
  end

  def skip_ws
    ws = @scanner.scan(LAYOUT)
    return ws, @scanner.pos
  end

  def lookahead(pat, ci)
    @scanner.pos = ci
    @scanner.scan(pat)
  end

  def with_literal(lit)
    # cache literal regexps as we go
    @lit_res[lit] ||= Regexp.new(Regexp.escape(lit))
    @scanner.pos = @ci
    val = @scanner.scan(@lit_res[lit])
    if val then
      ws, pos = skip_ws
      yield pos, ws
    end
  end

  def init_keywords(grammar)
    @keywords = grammar.literals.select { |kw| kw.match(SYMBOL) }
    @lit_res = {}
    # \ also has a follow restriction
    (['\\'] + @keywords).each do |kw|
      @lit_res[kw] = Regexp.new(Regexp.escape(kw) + "(?![a-zA-Z_$0-9])")
    end
  end


  def unescape(tk, kind)
    if kind == 'str' then
      tk[1..-2] # todo: backslash blues
    elsif kind == 'sym' then
      tk.sub(/^\\/, '')
    else
      tk
    end
  end

  def scan_token(kind)
    if kind == 'atom' then
      TOKENS.each_key do |type|
        tk = @scanner.scan(TOKENS[type])
        # return the token with its concrete (i.e. non-atom) type
        return tk, type.to_s if tk 
      end
      return nil
    end
    tk = @scanner.scan(TOKENS[kind.to_sym])
    return tk, kind
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/fold'
  require 'core/schema/tools/print'
  require 'yaml'
  gg = Loader.load('grammar.grammar')
  f = Fold.new(GrammarInterpreter)
  rg = f.fold(gg)
  #YAML.dump(rg, $stdout)
  gll = GLL2.new(rg)
  x = gll.parse(File.read('core/expr/models/expr.grammar'))
  Print.print(x)
end
