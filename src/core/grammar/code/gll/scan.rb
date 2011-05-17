
require 'strscan'
require 'core/system/library/cyclicmap'

module Scanner
  SYMBOL = "[\\\\]?([a-zA-Z_][a-zA-Z_0-9]*)(\\.[a-zA-Z_][a-zA-Z_0-9]*)*"

  TOKENS =  {
    sym: Regexp.new(SYMBOL),
    int: /[0-9]+/,
    str: /"(\\\\.|[^\"])*"/,
    real: /[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?/
  }
  
  # ([\\t\\n\\r\\f ]*(//[^\n]*\n)?)*
  LAYOUT = /(\s*(\/\/[^\n]*\n)?)*/

  def init_scanner(grammar, source)
    @keywords = CollectKeywords.run(grammar)
    @source = source
    @scanner = StringScanner.new(@source)
  end

  class CollectKeywords < CyclicCollectShy
    def Lit(this, accu)
      accu << this.value if this.value.match(SYMBOL)
    end

    def Regular(this, accu)
      accu << this.sep if this.sep && this.sep.match(SYMBOL)
    end
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


  def with_token(kind)
    @scanner.pos = @ci
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
      return if @keywords.include?(tk)
      ws, pos = skip_ws
      yield pos, unescape(tk, kind), ws 
    end
  end

  def skip_ws
    ws = @scanner.scan(LAYOUT)
    return ws, @scanner.pos
  end

  def with_literal(lit)
    @scanner.pos = @ci
    litre = Regexp.escape(lit)
    if @keywords.include?(lit) || lit == '\\' then
      re = Regexp.new(litre + "(?![a-zA-Z_$0-9])")
    else
      re = Regexp.new(litre)
    end
    val = @scanner.scan(re)
    if val then
      ws, pos = skip_ws
      yield pos, ws
    end
  end

  def eos?(pos)
    pos == @source.length
  end

end
