
require 'core/system/load/load'
require 'core/grammar/parse/parse'
require 'core/grammar/parse/scan' # for keywords...
require 'core/schema/tools/print'

# render an object into a grammar, to create a parse tree
class RenderClass < Dispatch
  include Paths

  def initialize()
    @factory = Factory.new(Loader.load('layout.schema'))
    @depth = 0
  end

  def Grammar(this, data)
    # ugly, should be higher up
    @root = data
    @literals = Scan.collect_keywords(this)
    return Rule(this.start, SingletonStream.new(data))
  end

  def recurse(pat, *args)
    #puts "#{' '*@depth}RENDER #{pat} #{args}"
    @depth = @depth + 1
    begin
      val = send(pat.schema_class.name, pat, *args)
    ensure
      @depth = @depth - 1
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
    throw :fail if this.arg.Lit? && this.arg.value != data
    recurse(this.arg, data)
  end
  
  def Value(this, stream)
    obj = stream.current
    throw :fail if obj.nil?
    s = @factory.Sequence()
    case this.kind
    when /str/ 
      s.elements << @factory.Text("\"")
      s.elements << @factory.Text(obj)
      s.elements << @factory.Text("\"")
    when /sym/
      if @literals.include?(obj) then
        s.elements << @factory.Text('\\')
      end
      s.elements << @factory.Text(obj.to_s)
    else
      s.elements << @factory.Text(obj.to_s)
    end
    s.elements << @factory.Text(" ")
    s
  end

  def Ref(this, stream)
    obj = stream.current
    throw :fail if obj.nil?

    it = PathVar.new("it")
    path = ToPath.to_path(this.path, it)
    bind = path.search(@root, obj)
    throw :fail if bind.nil?
    
    #puts "RENDER REF #{obj}=#{v}"
    return space(bind[it])  # TODO: need "." keys
  end

  def Lit(this, stream)
    obj = stream.current
    #puts "Rendering #{this.value} (#{this.value.class}) (obj = #{obj}, #{obj.class})"
    if obj.is_a?(String) then
      if this.value == obj then
        space(this.value)
      else
        throw :fail
      end
    end
    space(this.value)
  end

  def space(v)
    s = @factory.Sequence()
    s.elements << @factory.Text(v.to_s)
    s.elements << @factory.Text(" ")
    s
  end
  
  def Code(this, stream)
    obj = stream.current
    code = this.code.gsub(/=/, "==").gsub(/;/, "&&").gsub(/@/, "self.")
    throw :fail unless obj.instance_eval(code)
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
        s.elements << @factory.Text(this.sep) if i > 0 && this.sep
        s.elements << @factory.Break()
        pos = stream.length
        s.elements << recurse(this.arg, stream)
        stream.next if stream.length == pos
        i += 1
      end
      throw :fail if stream.length != 0
      return @factory.Group(@factory.Nest(s, 4))
    end
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
    @collection = collection.is_a?(ManyIndexedField) ? collection.values : collection 
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
    return RenderClass.new.recurse(grammar, obj)
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
