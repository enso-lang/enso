
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
    @need_space = false
    @indent_amount = 2
  end

  def Grammar(this, stream)
    # ugly, should be higher up
    @root = stream.current
    @literals = Scan.collect_keywords(this)
    Rule(this.start, SingletonStream.new(stream.current))
  end

  def recurse(pat, data)
    pair = [pat, data.current]
    if !@stack.include?(pair)
      @stack << pair 
      @depth = @depth + 1
      val = send(pat.schema_class.name, pat, data)
      #puts "#{' '*@depth}#{pat} #{data.current} ==> #{val}"
      @depth = @depth - 1
      @stack.pop
      val
    end
  end

  def Rule(this, stream)
    recurse(this.arg, stream)
  end
    
  def Call(this, stream)
    recurse(this.rule, stream)
  end

  def Alt(this, stream)
    this.alts.reduce(nil) do |memo, alt|
      memo || recurse(alt, stream.copy)
    end
  end

  def Sequence(this, stream)
    items = []
    ok = this.elements.all? do |x|
      item = recurse(x, stream)
      if item
        items << item
      end
    end
    @factory.Sequence(items) if ok
  end

  def Create(this, stream)
    obj = stream.current
    #puts "#{' '*@depth}[#{this.name}] #{obj}"
    if !obj.nil? && obj.schema_class.name == this.name
      stream.next
      recurse(this.arg, SingletonStream.new(obj))
    else
      nil
    end
  end

  def Field(this, stream)
    obj = stream.current
    #puts "#{' '*@depth}FIELD #{this.name}"
    if this.name == "_id"
      data = SingletonStream.new(obj._id)
    else
      fld = obj.schema_class.all_fields[this.name]
      raise "Unknown field #{obj.schema_class.name}.#{this.name}" if !fld
      if fld.many
        data = ManyStream.new(obj[this.name])
      else
        data = SingletonStream.new(obj[this.name])
      end
    end
    # handle special case of [[ field:"text" ]] in a grammar 
    if this.arg.Lit? && this.arg.value != obj[this.name]
      nil
    else
      recurse(this.arg, data)
    end
  end
  
  def Value(this, stream)
    obj = stream.current
    if !obj.nil?
      case this.kind
      when "str" 
        output(obj.inspect) if obj.is_a?(String)
      when "sym"
        if @literals.include?(obj) then
          output('\\' + obj.to_s)
        else
          output(obj.to_s)
        end
      when "int"
        output(obj.to_s) if obj.is_a?(Fixnum)
      when "real"
        output(obj.to_s) if obj.is_a?(Float)
      when "atom"
        output(obj.to_s)
      else
        raise "Unknown type #{this.kind}"
      end
    end
  end

  def Ref(this, stream)
    obj = stream.current
    if !obj.nil?
      it = PathVar.new("it")
      path = ToPath.to_path(this.path, it)
      bind = path.search(@root, obj)
      
      #puts "#{' '*@depth}RENDER REF #{obj}=#{v}"
      !bind.nil? && output(bind[it])  # TODO: need "." keys
    end
  end

  def Lit(this, stream)
    obj = stream.current
    #puts "#{' '*@depth}Rendering #{this.value} (#{this.value.class}) (obj = #{obj}, #{obj.class})"
    if !obj.is_a?(String) || this.value == obj
      output(this.value)
    end
  end

  def output(v)
    if @need_space
      s = @factory.Sequence()
      s.elements << @factory.Text(" ")
      s.elements << @factory.Text(v.to_s)
      s
    else
      @need_space = true
      @factory.Text(v.to_s)    
    end
  end
  
  def Code(this, stream)
    obj = stream.current
    if this.schema_class.defined_fields.map{|f|f.name}.include?("code") && this.code != ""
     # FIXME: this case is needed to parse bootstrap grammar
      code = this.code.gsub("=", "==").gsub(";", "&&").gsub("@", "self.")
      ok = obj.instance_eval(code)
    else
      ok = Interpreter(EvalExpr).eval(this.expr, env: ObjEnv.new(obj))
    end
    ok && @factory.Sequence()
  end

  def Regular(this, stream)
    if !this.many
      # optional
      recurse(this.arg, stream) || @factory.Sequence()
    else
      if stream.length > 0 || this.optional
        s = @factory.Sequence()
        i = 0
        ok = true
        while ok && stream.length > 0
          @needBreak = true
          if i > 0 && this.sep
            v = recurse(this.sep, stream)
            if v
              s.elements << v
            else
              ok = false
            end
          end
          if ok
            s.elements << @factory.Break(true) if @needBreak # optional break
            pos = stream.length
            v = recurse(this.arg, stream)
            if v
              s.elements << v
              stream.next if stream.length == pos
              i = i + 1
            else
              ok = false
            end
          end
        end
        ok && (stream.length == 0) && @factory.Group(@factory.Nest(s, @indent_amount))
      end
    end
  end
  
  def NoSpace(this, stream)
    @need_space = false
    @factory.Text("")
  end
  
  def Break(this, stream)
    @needBreak = false
    @need_space = false
    @factory.Break(false) # hard break
  end
  
end

class SingletonStream
  def initialize(data, used = false)
    @data = data
    @used = used
  end
  def length
    @used ? 0 : 1
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
    (@index < @collection.length) && @collection[@index]
  end
  def next
    @index = @index + 1
  end
  def copy
    ManyStream.new(@collection, @index)
  end
end


def Render(grammar, obj)
  r = RenderClass.new.recurse(grammar, SingletonStream.new(obj))
  if !r
    puts "-"*50
    raise "ERROR: Could not render #{obj}"
  end
  r
end

if __FILE__ == $0 then
  if !ARGV[0] then
    $stderr << "Usage: render.rb <model>"
    exit!(1)
  end
  name = ARGV[0]
  m = Loader.load(name)
  filename = name.split("/")[-1]
  type = filename.split(".")[-1]
  g = Loader.load("#{type}.grammar")
  DisplayFormat.print(g, m)
end


