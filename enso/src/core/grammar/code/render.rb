
require 'cyclicmap'
require 'grammar/cpsparser'

# render an object into a grammar, to create a parse tree
class Render < Dispatch
  def initialize()
    @factory = Factory.new(LayoutSchema.schema)
  end

  def Grammar(this, obj)
    # ugly, should be higher up
    @literals = CPSParser::CollectKeywords.run(this)
    recurse(this.start, obj)
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
    @factory.Sequence(this.elements.map {|x| recurse(x, obj)});
  end

  def Create(this, obj)
    throw :fail if obj.schema_class.name != this.name
    recurse(this.arg, obj)
  end

  def Field(this, obj)
    data = obj[this.name]
    #puts "FIELD #{this.name} #{obj} #{data}"
    
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
      s.elements << @factory.Text(obj)
    else
      s.elements << @factory.Text(obj)
    end
    s.elements << @factory.Text(" ")
    s
  end

  def Ref(this, obj)
    throw :fail if obj.nil?
    space(obj[SchemaSchema.key(obj.schema_class).name])  # need "." keys
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
    s.elements << @factory.Text(v)
    s.elements << @factory.Text(" ")
    s
  end
  
  def Code(this, obj)
    code = this.code.gsub(/=/, "==").gsub(/;/, "&&").gsub(/@/, "self.");
    throw :fail unless obj.instance_eval(code)
    @factory.Sequence()
  end
  
  def Regular(this, obj)
    if !this.many
      catch :fail do
        recurse(this.arg, obj)
      end
      return @factory.Sequence()
    else
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

def main
  require 'schema/factory'
  require 'grammar/layoutschema'
  require 'tools/print'
  require 'grammar/grammargrammar'

  render = Render.new
  pt = render.recurse(GrammarGrammar.grammar, GrammarGrammar.grammar)  
  Print.new.recurse(pt, LayoutSchema.print_paths)
end

if __FILE__ == $0 then
  main
end
