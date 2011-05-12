
require 'core/schema/code/factory'
require 'core/schema/tools/print'
require 'core/instance/code/instantiate'
require 'core/grammar/code/implode'
require 'core/system/load/load'
require 'strscan'


class CPSParser


  def self.loadFile(path, grammar, schema)
    self.load(path, File.read(path), grammar, schema)
  end
  
  def self.load(path, source, grammar, schema)
    data = load_raw(path, source, grammar, schema)
    data.finalize
    return data
  end
  
  def self.load_raw(path, source, grammar, schema)
    tree = CPSParser.parse(path, source, grammar)
      
    #Print.print(tree)
    inst2 = Instantiate.new(Factory.new(schema))
    inst2.run(OldImplode.implode(tree))
  end

  def self.parseFile(path, grammar, ptf = Factory.new(Loader.load('parsetree.schema')))
    parse(path, File.read(path), grammar, ptf)
  end
  
  def self.parse(path, source, grammar, ptf = Factory.new(Loader.load('parsetree.schema')))
    parse = CPSParser.new(source, ptf, path)
    parse.run(grammar)
  end



  SYMBOL = "[\\\\]?([a-zA-Z_$][a-zA-Z_$0-9]*)(\\.[a-zA-Z_$][a-zA-Z_$0-9]*)*"

  TOKENS =  {
    sym: Regexp.new(SYMBOL),
    int: /[0-9]+/,
    str: /"(\\\\.|[^\"])*"/,
    real: /[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?/
  }
  
  # ([\\t\\n\\r\\f ]*(//[^\n]*\n)?)*
  LAYOUT = /(\s*(\/\/[^\n]*\n)?)*/

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
    @indent = 0;
  end

  def run(grammar)
    @keywords = CollectKeywords.run(grammar) 
    ws =  @scanner.scan(LAYOUT)
    x = recurse(grammar, @scanner.pos) do |pos, tree|
      if eos?(pos) then
        return @factory.ParseTree(@path, tree, ws)
      else
        pos
      end
    end
    raise "Parse error at #{x}"
  end

  # todo: move to generic visit/dispatch class
  def recurse(obj, *args, &block)
    send(obj.schema_class.name, obj, *args, &block)
  end

  def unescape(tk, kind)
    if kind == 'str' then
      tk[1..-2]
    elsif kind == 'sym' then
      tk.sub(/^\\/, '')
    else
      tk
    end
  end


  def with_token(pos, kind)
    @scanner.pos = pos
    tk = nil
    if kind == 'atom' then
      TOKENS.each_key do |type|
        tk = @scanner.scan(TOKENS[type])
        if tk then
          kind = type.to_s
          break
        end
      end
    else
      tk = @scanner.scan(TOKENS[kind.to_sym])
    end
    if tk then
      return pos if @keywords.include?(tk)
      ws = @scanner.scan(LAYOUT)
      yield @scanner.pos, unescape(tk, kind), ws 
    else
      return pos
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
    else
      return pos
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
        return pos1 if entry.subsumed?(pos1) 
        entry.results[pos1] = tree
        entry.conts.inject(pos1) do |x, c|
          y = c.call(pos1, tree)
          #puts "Y = #{y}"
          x > y ? x : y 
        end
      end
    else
      entry.conts << block
      # NB: keys to prevent modifying hash during iterations
      entry.results.keys.inject(pos) do |x, pos1|
        y = block.call(pos1, entry.results[pos1])
        x > y ? x : y
      end
    end
  end

  def debug(msg, this, pos)
    #puts "#{msg} at #{pos}"
    #Print.print(this)
  end

  def Sequence(this, pos, &block)
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
    x = f.call(0, pos, [])
    #puts "x in seq: #{x}"
    return x
  end

  def Alt(this, pos, &block)
    this.alts.inject(pos) do |x, a|
      y = recurse(a, pos, &block)
      x > y ? x : y
    end
  end

  def Create(this, pos, &block)
    debug("CREATE", this, pos)
    #puts "Parsing create #{this}"
    recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, @factory.Create(this.name, tree))
    end
  end

  def Field(this, pos, &block)
    debug("FIELD", this, pos)
    #puts "Parsing field #{this.name}"
    recurse(this.arg, pos) do |pos1, tree|
      #puts "BLOCK: #{block}"
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
    x = recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, [tree])
    end
    y = block.call(pos, [])
    x > y ? x : y
  end

  ## NB: iters are right-recursive (otherwise we have to memoize them)
  ## This also means that iter'ed symbols should not be nullable
  ## otherwise they become (hidden) left-recursive as well.

  def iter(this, pos, &block)
    x = recurse(this.arg, pos) do |pos1, tree1|
      iter(this, pos) do |pos2, trees|
        block.call(pos2, [tree1, *trees])
      end
    end
    y = recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, [tree])
    end
    x > y ? x : y
  end


  def iter_star(this, pos, &block)
#     lst = []
#     success = true
#     while success do
#       success = false
#       puts "While loop; pos = #{pos}"
#       recurse(this.arg, pos) do |pos1, tree1|
#         puts "Adding tree1: #{tree1}"
#         lst << tree1
#         pos = pos1
#         success = true
#         pos1
#       end
#       puts "While loop failed at: #{pos}"
#     end
#     block.call(pos, lst)

    x = recurse(this.arg, pos) do |pos1, tree1|
      iter_star(this, pos1) do |pos2, trees|
        block.call(pos2, [tree1, *trees])
      end
    end
    #puts "x in iter-star: #{x}"
    y = block.call(pos, [])
    #puts "block = #{block}"
    #puts "Y in iter-star: #{y}"
    x > y ? x : y
  end

  def iter_sep(this, pos, &block)
    x = recurse(this.arg, pos) do |pos1, tree1|
      with_literal(pos1, this.sep) do |pos2, ws|
        iter_sep(this, pos2) do |pos3, trees|
          block.call(pos3, [tree1, @factory.Lit(this.sep, ws), *trees])
        end
      end
    end
    y = recurse(this.arg, pos) do |pos1, tree|
      block.call(pos1, [tree])
    end
    x > y ? x : y
  end

  def iter_star_sep(this, pos, &block)
    x = iter_sep(this, pos, &block)
    y = block.call(pos, [])
    x > y ? x : y
  end

end


