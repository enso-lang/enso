
require 'core/system/load/load'
require 'core/grammar/parse/parse'
require 'core/grammar/parse/scan' # for keywords...
require 'core/schema/tools/print'
require 'core/expr/code/impl'

# render an object into a grammar, to create a parse tree
class RenderClass < Dispatch
  include Paths

  def initialize()
    @factory = ManagedData::Factory.new(Loader.load('layout.schema'))
    @depth=0
    @stack = []
    @current = nil
    @needSpace = false
  end

  def Grammar(this, stream)
    # ugly, should be higher up
    @root = stream.current
    @literals = Scan.collect_keywords(this)
    return Rule(this.start, SingletonStream.new(stream.current))
  end

  def recurse(pat, *args)
    throw :fail if @stack.include? pat
    @stack.clear if @current != args[0].current
    @current = args[0].current
    @stack << pat
    @depth=@depth+1
    begin
      val = send(pat.schema_class.name, pat, *args)
    ensure
      @depth=@depth-1
    end
    return val
  end

  def Rule(this, stream)
    recurse(this.arg, stream)
  end
    
  def Call(this, stream)
    recurse(this.rule, stream)
  end

  def Alt(this, stream)
    this.alts.each do |alt|
      catch :fail do
        return recurse(alt, stream.copy)
      end
    end
    throw :fail
  end

  def Sequence(this, stream)
    @factory.Sequence(this.elements.map {|x| recurse(x, stream)})
  end

  def Create(this, stream)
    obj = stream.current
    #puts "[#{this.name}] #{obj}"
    throw :fail if obj.nil? || obj.schema_class.name != this.name
    stream.next
    recurse(this.arg, SingletonStream.new(obj))
  end

  def Field(this, stream)
    obj = stream.current
    if this.name == "_id"
      data = SingletonStream.new(obj._id)
    else
      if obj.schema_class.all_fields[this.name].many
        data = ManyStream.new(obj[this.name])
      else
        data = SingletonStream.new(obj[this.name])
      end
    end
    # handle special case of [[ field:"text" ]] in a grammar 
    throw :fail if this.arg.Lit? && this.arg.value != obj[this.name]
    recurse(this.arg, data)
  end
  
  def Value(this, stream)
    obj = stream.current
    throw :fail if obj.nil?
    case this.kind
    when /str/ 
      val = "\"" + obj + "\""
    when /sym/
      if @literals.include?(obj) then
        val = '\\' + obj.to_s
      else
        val = obj.to_s
      end
    else
      val = obj.to_s
    end
    output(val)
  end

  def Ref(this, stream)
    obj = stream.current
    throw :fail if obj.nil?

    it = PathVar.new("it")
    path = ToPath.to_path(this.path, it)
    bind = path.search(@root, obj)
    throw :fail if bind.nil?
    
    #puts "RENDER REF #{obj}=#{v}"
    return output(bind[it])  # TODO: need "." keys
  end

  def Lit(this, stream)
    obj = stream.current
    #puts "Rendering #{this.value} (#{this.value.class}) (obj = #{obj}, #{obj.class})"
    if obj.is_a?(String) then
      if this.value == obj then
        output(this.value)
      else
        throw :fail
      end
    end
    output(this.value)
  end

  def output(v)
    if @needSpace
      s = @factory.Sequence()
      s.elements << @factory.Text(" ")
      s.elements << @factory.Text(v.to_s)
      s
    else
      @needSpace = true
      @factory.Text(v.to_s)    
    end
  end
  
  def Code(this, stream)
    obj = stream.current
    if this.code!="" # FIXME: this case is needed to parse bootstrap grammar
      code = this.code.gsub(/=/, "==").gsub(/;/, "&&").gsub(/@/, "self.")
      ok = obj.instance_eval(code)
    else
      ok = Interpreter(EvalCommandTest).eval(this.expr, :env=>ObjEnv.new(obj))
    end
    throw :fail unless ok
    @factory.Sequence()
  end

  def Regular(this, stream)
    if !this.many
      # optional
      catch :fail do
        return recurse(this.arg, stream)
      end
      return @factory.Sequence()
    else
      throw :fail if stream.length == 0 && !this.optional
      s = @factory.Sequence()
      i = 0
      while stream.length > 0
        @needBreak = true
        s.elements << recurse(this.sep, stream) if i > 0 && this.sep
        s.elements << @factory.Break(true) if @needBreak # optional break
        pos = stream.length
        s.elements << recurse(this.arg, stream)
        stream.next if stream.length == pos
        i += 1
      end
      throw :fail if stream.length != 0
      return @factory.Group(@factory.Nest(s, 4))
    end
  end
  
  def NoSpace(this, stream)
    @needSpace = false
    @factory.Text("")
  end
  
  def Break(this, stream)
    @needBreak = false
    @factory.Break(false) # hard break
  end
  
end

class SingletonStream
  def initialize(data, used = false)
    @data = data
    @used = used
  end
  def length
    used ? 0 : 1
  end
  def current
    @used ? nil : @data
  end
  def next
    @used = true
  end
  def copy
    SingletonStream.new(@data, @used)
  end
end

class ManyStream
  def initialize(collection, index = 0)
    @collection = collection.is_a?(Array) ? collection : collection.values 
    @index = index
  end
  def length
    @collection.length - @index
  end
  def current
    return nil if @index >= @collection.length
    return @collection[@index]
  end
  def next
    @index += 1
  end
  def copy
    ManyStream.new(@collection, @index)
  end
end


def Render(grammar, obj)
  catch :fail do
    return RenderClass.new.recurse(grammar, SingletonStream.new(obj))
  end
  puts "-"*50
#  Print.print(obj)
  raise "ERROR: Could not render #{obj}"
end

def main
  require 'core/schema/tools/print'
  gg = Loader.load('grammar.grammar')

  pt = Render(gg, gg)  
  Print.print(pt)
end

if __FILE__ == $0 then
  main
end
