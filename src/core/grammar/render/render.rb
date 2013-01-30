
require 'core/system/load/load'
require 'core/grammar/parse/parse'
require 'core/grammar/parse/scan' # for keywords...
require 'core/schema/tools/print'
require 'core/expr/code/impl'

# render an object into a grammar, to create a parse tree
class RenderClass < Dispatch
  include Paths

  def initialize(slash_keywords = true)
    @factory = ManagedData.new(Loader.load('layout.schema'))
    @depth=0
    @stack = []
    @indent_amount = 2
    @slash_keywords = slash_keywords
  end

  def render(grammar, obj)
    r = recurse(grammar, SingletonStream.new(obj))
    if !r
      puts "-"*50
      Print.print(@last_pattern)
      puts "-"*50
      Print.print(@last_object)
      puts "-"*50
      raise "Could not render AT:#{@last_pattern}\n FOR #{@last_object}"
    end
    r
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
      #puts "#{' '*@depth}#{pat} #{data.current}"
      @depth = @depth + 1
      val = send(pat.schema_class.name, pat, data)
      @depth = @depth - 1
      #puts "#{' '*@depth}#{pat} #{data.current} ==> #{val}"
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
    items = true
    ok = this.elements.all? do |x|
      item = recurse(x, stream)
      if item
        if item == true
          true
        else
          if items.is_a?(Array)
            items << item
          elsif items != true
            items = [items, item]
          else
            items = item
          end
        end
      end
    end
    items if ok
  end

  def Create(this, stream)
    obj = stream.current
    #puts "#{' '*@depth}[#{this.name}] #{obj}"
    if !obj.nil? && obj.schema_class.name == this.name
      @last_pattern = this
      @last_object = obj
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
    if this.arg.Lit?
      if this.arg.value == obj[this.name]
        this.arg.value
      end
    else
      recurse(this.arg, data)
    end
  end
  
  def Value(this, stream)
    obj = stream.current
    if !obj.nil?
      if !(obj.is_a?(String) || obj.is_a?(Fixnum)  || obj.is_a?(Float))
        raise "Data is not literal #{obj}"
      end
      case this.kind
      when "str"
        output(obj.inspect) 
      when "sym"
        if @slash_keywords && @literals.include?(obj) then
          output('\\' + obj.to_s)
        else
          output(obj.to_s)
        end
      when "int"
        output(obj.to_s)
      when "real"
        output(obj.to_s)
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
      output(bind[it]) if !bind.nil? # TODO: need "." keys
    end
  end

  def Lit(this, stream)
    obj = stream.current
    #puts "#{' '*@depth}Rendering #{this.value} (#{this.value.class}) (obj = #{obj}, #{obj.class})"
    output(this.value)
  end

  def output(v)
    v
  end
  
  def Code(this, stream)
    obj = stream.current
    if this.schema_class.defined_fields.map{|f|f.name}.include?("code") && this.code != ""
     # FIXME: this case is needed to parse bootstrap grammar
      code = this.code.gsub("=", "==").gsub(";", "&&").gsub("@", "self.")
      obj.instance_eval(code)
    else
      Interpreter(EvalExpr).eval(this.expr, env: ObjEnv.new(obj, @localEnv))
    end
  end

  def Regular(this, stream)
    if !this.many
      # optional
      recurse(this.arg, stream) || true
    else
      if stream.length > 0 || this.optional
        oldEnv = @localEnv
        @localEnv = HashEnv.new
        @localEnv['_length'] = stream.length
        s = []
        i = 0
        ok = true
        while ok && stream.length > 0
          @localEnv['_index'] = i
          @localEnv['_first'] = (i == 0)
          @localEnv['_last'] = (stream.length == 1)
          if i > 0 && this.sep
            v = recurse(this.sep, stream)
            if v
              s << v
            else
              ok = false
            end
          end
          if ok
            pos = stream.length
            v = recurse(this.arg, stream)
            if v
              s << v
              stream.next if stream.length == pos
              i = i + 1
            else
              ok = false
            end
          end
        end
        @localEnv = oldEnv
        s if ok && (stream.length == 0)
      end
    end
  end
  
  def NoSpace(this, stream)
    this
  end
  
  def Indent(this, stream)
    this
  end
  
  def Break(this, stream)
    this
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


def Render(grammar, obj, slash_keywords = true)
  RenderClass.new(slash_keywords).render(grammar, obj)
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


