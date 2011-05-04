
require 'grammar/parsetree'
require 'schema/factory'
require 'grammar/grammargrammar'
require 'grammar/instantiate'

require 'strscan'


class CPSParser

  def self.load(path, grammar, schema)
    data = load_raw(path, grammar, schema)
    data.finalize
    return data
  end
  
  def self.load_raw(path, grammar, schema)
    tree = CPSParser.parse(path, grammar)
    inst2 = Instantiate.new(Factory.new(schema))
    inst2.run(tree)
  end

  def self.parse(path, grammar, ptf = Factory.new(ParseTreeSchema.schema))
    parse = CPSParser.new(File.read(path), ptf, path)
    parse.run(grammar)
  end



  SYMBOL = "[\\\\]?([a-zA-Z_$][a-zA-Z_$0-9]*)(\\.[a-zA-Z_$][a-zA-Z_$0-9]*)*"
  
  TOKENS =  {
    bool: /true|false/,
    sym: Regexp.new(SYMBOL),
    int: /[0-9]+/,
    str: /"(\\\\.|[^"])*"/,
    real: /[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?/ 
  }
  
  LAYOUT = /\s*/

  class CollectKeywords < CyclicCollectShy
    def Lit(this, accu)
      accu << this.value if this.value.match(SYMBOL)
    end

    def Regular(this, accu)
      accu << this.sep if this.sep && this.sep.match(SYMBOL)
    end
  end

  def initialize(source, factory, path = '-')
    @source = source
    @table = Table.new
    @factory = factory
    @scanner = StringScanner.new(@source)
    @path = path
  end

  def run(grammar)
    @keywords = CollectKeywords.run(grammar) 
    ws = @scanner.scan(LAYOUT)
    recurse(grammar, @scanner.pos) do |pos, tree|
      if eos?(pos) then
        return @factory.ParseTree(@path, tree, ws)
      end
    end
    return nil
  end

  # todo: move to generic visit/dispatch class
  def recurse(obj, *args, &block)
    send(obj.schema_class.name, obj, *args, &block)
  end

  def with_token(pos, kind)
    @scanner.pos = pos
    tk = @scanner.scan(TOKENS[kind.to_sym])
    if tk then
      return if @keywords.include?(tk)
      ws = @scanner.scan(LAYOUT)
      yield @scanner.pos, tk, ws
    end
  end

  def with_literal(pos, lit)
    @scanner.pos = pos
    litre = Regexp.escape(lit)
    if @keywords.include?(lit) || lit == '\\' then
      re = Regexp.new(litre + "(?![a-zA-Z_$0-9])")
    else
      re = Regexp.new(litre)
    end
    val = @scanner.scan(re)
    if val then
      ws = @scanner.scan(LAYOUT)
      yield @scanner.pos, ws
    end
  end

  def eos?(pos)
    pos == @source.length
  end


  class Table
    def initialize
      @table = {}
    end

    def [](cont, pos)
      key = cont.to_s
      @table[key] ||= {}
      @table[key][pos] ||= Entry.new
    end
  end

  class Entry
    attr_accessor :conts, :results
    def initialize
      @conts = []
      @results = {}
    end

    def subsumed?(pos)
      @results.include?(pos)
    end
  end
  
  def Grammar(obj, pos, &block)
    recurse(obj.start, pos, &block)
  end

  def Rule(this, pos, &block)
    #puts "Parsing rule: #{this} #{pos}"
    entry = @table[this, pos]
    if entry.conts.empty? then
      entry.conts << block
      recurse(this.arg, pos) do |pos1, tree|
        return if entry.subsumed?(pos1) 
        entry.results[pos1] = tree
        entry.conts.each do |c|
          c.call(pos1, tree)
        end
      end
    else
      entry.conts << block
      # NB: keys to prevent modifying hash during iterations
      entry.results.keys.each do |pos1|
        block.call(pos1, entry.results[pos1])
      end
    end
  end

  def Sequence(this, pos, &block)
    #puts "Parsing sequence: #{this} at #{pos}"
    f = lambda do |i, pos, lst| 
      if i == this.elements.length then
        s = @factory.Sequence
        lst.each do |l|
          s.elements << l
        end
        block.call(pos, s)
      else
        recurse(this.elements[i], pos) do |pos1, tree|
          f.call(i + 1, pos1, [*lst, tree])
        end
      end
    end
    f.call(0, pos, [])
  end

  def Alt(this, pos, &block)
    this.alts.each do |a|
      recurse(a, pos, &block)
    end
  end

  def Create(this, pos, &block)
    #puts "Parsing create #{this}"
    recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, @factory.Create(this.name, tree))
    end
  end

  def Field(this, pos, &block)
    #puts "Parsing field #{this}"
    recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, @factory.Field(this.name, tree))
    end
  end

  def Value(this, pos, &block)
    #puts "Parsing value: #{this.kind} at #{pos}"
    with_token(pos, this.kind) do |pos1, tk, ws|
      #puts "Sucess: #{tk} ws = '#{ws}'"
      block.call(pos1, @factory.Value(this.kind, tk, ws))
    end
  end

  def Code(this, pos, &block)
    block.call(pos, @factory.Code(this.code))
  end

  def Ref(this, pos, &block)
    with_token(pos, 'sym') do |pos1, tk, ws|
      block.call(pos1, @factory.Ref(tk, ws))
    end
  end

  def Call(this, pos, &block)
    recurse(this.rule, pos, &block)
  end

  def Lit(this, pos, &block)
    #puts "Parsing literal: #{this.value}"
    with_literal(pos, this.value) do |pos1, ws|
      #puts "Success: #{pos1}, ws = '#{ws}'"
      block.call(pos1, @factory.Lit(this.value, ws)) 
    end
  end

  def Regular(this, pos, &block)
    regular(this, pos) do |pos1, trees|
      t = @factory.Sequence
      trees.each do |k|
        t.elements << k
      end
      block.call(pos1, t)
    end
  end

  # a helper function that produces normal lists of trees
  def regular(this, pos, &block)
    if this.optional && !this.many && !this.sep then
      optional(this, pos, &block)
    elsif !this.optional && this.many && !this.sep then
      iter(this, pos, &block)
    elsif this.optional && this.many && !this.sep then
      iter_star(this, pos, &block)
    elsif !this.optional && this.many && this.sep then
      iter_sep(this, pos, &block)
    elsif this.optional && this.many && this.sep then
      iter_star_sep(this, pos, &block)
    else
      raise "Inconsistent Regular: #{this}"
    end
  end

  def optional(this, pos, &block)
    recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, [tree])
    end
    block.call(pos, [])
  end

  ## NB: iters are right-recursive (otherwise we have to memoize them)
  ## This also means that iter'ed symbols should not be nullable
  ## otherwise they become (hidden) left-recursive as well.

  def iter(this, pos, &block)
    recurse(this.arg, pos) do |pos1, tree1|
      iter(this, pos) do |pos2, trees|
        block.call(pos2, [tree1, *trees])
      end
    end
    recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, [tree])
    end
  end


  def iter_star(this, pos, &block)
    recurse(this.arg, pos) do |pos1, tree1|
      iter_star(this, pos1) do |pos2, trees|
        block.call(pos2, [tree1, *trees])
      end
    end
    block.call(pos, [])
  end

  def iter_sep(this, pos, &block)
    recurse(this.arg, pos) do |pos1, tree1|
      with_literal(pos1, this.sep) do |pos2, ws|
        iter_sep(this, pos2) do |pos3, trees|
          block.call(pos3, [tree1, @factory.Lit(this.sep, ws), *trees])
        end
      end
    end
    recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, [tree])
    end
  end

  def iter_star_sep(this, pos, &block)
    iter_sep(this, pos, &block)
    block.call(pos, [])
  end

end


if __FILE__ == $0 then
  grammar = GrammarGrammar.grammar
  bla = CPSParser.parse('grammar/grammar.grammar', grammar)
  p bla
end


