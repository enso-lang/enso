#### pop when creating a node (like reduce)

require 'set'
require 'ostruct'

require 'core/grammar/code/gll/gll'
require 'core/grammar/code/gll/gss'
require 'core/grammar/code/gll/todot'
require 'core/grammar/code/gll/sppf'
require 'core/grammar/code/gll/scan'
require 'core/grammar/code/gll/parsers'


class GLLDebug < GLL

  def initialize(org)
    super(org)
    @indent = 0
  end

  def iputs(m)
    puts "#{' ' * @indent}#{m}"
  end

  def item(exp, elts, dot)
    iputs "item needed for #{exp} with elts = #{elts} at #{dot}"
    super(exp, elts, dot)
  end

  def recurse(this, *args)
    iputs "recursing for #{this}: #{args}"
    super(this, *args)
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
    iputs "adding #{parser} with u = #{u}, i = #{i}, w = #{w}"
    super(parser, u, i, w)
  end

  def pop
    iputs "popping"
    @indent -= 1
    super
  end

  def create(item)
    iputs "creating for item #{item}"
    @indent += 1
    super(item)
  end

  def chain(this, nxt)
    iputs "chaining #{this} and item #{nxt}"
    super(this, nxt)
  end

  def continue(nxt)
    iputs "continue with #{nxt} if non-nil"
    super(nxt)
  end

  def empty(item, nxt)
    iputs "creating empty for #{item}"
    super(item, nxt)
  end

  def terminal(type, pos, value, ws, nxt)
    iputs "terminal #{type} up to #{pos} value = '#{value}', ws = '#{ws}'"
    super(type, pos, value, ws, nxt)
  end
end

