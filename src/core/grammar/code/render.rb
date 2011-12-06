
require 'core/system/load/load'
require 'core/grammar/code/parse'
require 'core/grammar/code/gll/scan' # for keywords...
require 'core/schema/tools/print'

# render an object into a grammar, to create a parse tree
class RenderClass < Dispatch
  def initialize()
    @factory = Factory.new(Loader.load('layout.schema'))
    @depth = 0
  end

  def Grammar(this, obj)
    # ugly, should be higher up
    @literals = Scan.collect_keywords(this)
    return Rule(this.start, obj)
  end

  def recurse(obj, *args)
    #puts "#{' '*@depth}RENDER #{obj} #{args}"
    @depth = @depth + 1
    begin
      val = send(obj.schema_class.name, obj, *args)
    ensure
      @depth = @depth - 1
    end
    return val
  end

  def Rule(this, obj)
    recurse(this.arg, obj)
  end
    
  def Call(this, obj)
    recurse(this.rule, obj)
  end

  def Alt(this, obj)
    this.alts.each do |alt|
      catch :fail do
        return recurse(alt, obj)
      end
    end
    throw :fail
  end

  def Sequence(this, obj)
    @factory.Sequence(this.elements.map {|x| recurse(x, obj)})
  end

  def Create(this, obj)
    throw :fail if obj.nil? || obj.schema_class.name != this.name
    recurse(this.arg, obj)
  end

  def Field(this, obj)
    if this.name == "_id"
      data = obj._id
    else
      data = obj[this.name]
    end
    # handle special case of [[ field:"text" ]] in a grammar 
    throw :fail if this.arg.Lit? && this.arg.value != data

    recurse(this.arg, data)
  end
  
  def Value(this, obj)
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

  def Ref(this, obj)
    throw :fail if obj.nil?
    key = ClassKey(obj.schema_class)
    if key
      v = obj[key.name]
      #puts "RENDER REF #{obj}=#{v}"
      return space(v)  # TODO: need "." keys
    else
      return space(obj._id)
    end
  end

  def Ref2(this, obj)
    raise "Not supported yet"
    # solve for the value of "it"
  end

  def Lit(this, obj)
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
  
  def Code(this, obj)
    code = this.code.gsub(/=/, "==").gsub(/;/, "&&").gsub(/@/, "self.")
    throw :fail unless obj.instance_eval(code)
    @factory.Sequence()
  end

  def Regular(this, obj)
    if !this.many
      catch :fail do
        return recurse(this.arg, obj)
      end
      return @factory.Sequence()
    else
      throw :fail if obj.length == 0 && !this.optional
      s = @factory.Sequence()
      obj.each_with_index do |x, i|
        s.elements << @factory.Text(this.sep) if i > 0 && this.sep
        s.elements << @factory.Break()
        s.elements << recurse(this.arg, x)
      end
      return @factory.Group(@factory.Nest(s, 4))
    end
  end
end

def Render(grammar, obj)
  catch :fail do
    return RenderClass.new.recurse(grammar, obj)
  end
  puts "-"*50
  Print.print(obj)
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
