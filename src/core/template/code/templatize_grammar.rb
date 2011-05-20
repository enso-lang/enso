
require 'core/system/load/load'
require 'core/schema/tools/copy'
require 'core/schema/tools/union'

require 'core/schema/tools/print'

class TemplatizeGrammar < Copy
  def initialize()
    @factory = Factory.new(Loader.load("grammar.schema"))
    @rule_number = 0
    @memo = {}
  end
  
  def templatize(source, target_klass)
    @grammar = Loader.load_text 'grammar', @factory, <<-GRAMMAR
      start Expression
      Ref ::= [Ref] label:symExpression
      intExpression ::= [LiteralExpression] value:int | "[" Expression "]"
      strExpression ::= [LiteralExpression] value:str | "[" Expression "]"
      symExpression ::= [LiteralExpression] value:sym | "[" Expression "]"

      Expression ::= [NameExpression] name:sym 
                  | [LiteralExpression] value:atom 
                  | [AddExpression] args:{ Expression "+" }+
                  | [DotExpression] args:{ FieldExpression "." }+
                  
      FieldExpression ::= [FieldExpression] field:sym
    GRAMMAR
    #DisplayFormat.print(Loader.load("grammar.grammar"), @grammar)
    
    @grammar.start = copy(source.start, nil, target_klass)
    #Print.print(@grammar)
    return @grammar.finalize
  end
  
  def register(source, target)
    super(source, target)
    if source.Rule?
      @grammar.rules << target
    end
  end

  def copy(old, field, type)
    #puts "TEMP obj=#{old} field=#{field} type=#{type}"
    if old.Field?
      field = type.all_fields[old.name]
      raise "Unknown field '#{old.name}' in type #{type}" unless field
      result = super(old, field, field.type)
    elsif old.Create?
      klass = type.schema.classes[old.name]
      raise "Unknown class '#{old.name}'" unless klass
      result = super(old, field, klass)
    else
      result = super(old, field, type)
    end
    if old.Field?
      field = type.all_fields[old.name]
      type = field.type
      #puts "  NOW obj=#{old} field=#{field} type=#{type}: #{old.name}"
      if field.traversal && !field.many && !type.Primitive?
        # change foo:Foo  ==> foos:FooAlt
        # change foo:(... Foo...)  ==> foos:NewAlt
        #    where templatize(New ::= ... Foo...)
        call = ensure_call(old.arg, type)
        subs = makeTemplate(call.rule.name, type.name, false)
        return @factory.Call(subs)
      end
    elsif old.Regular? and old.many
      #puts "REGULAR obj=#{old} field=#{field} type=#{type}"
      if field.traversal
        raise "Repetition without many-valued field" if !field || !field.many
        # make the grammar rules
        # change foos:{Foo Sep}* ==> foos:([FooSeq] items: {FooAlt Sep}*)
        call = ensure_call(old.arg, type)
        subs = makeTemplate(call.rule.name, type.name, old.sep)
        return @factory.Call(subs)
      end
    elsif old.Ref?
      return @factory.Call(@grammar.rules["Ref"])
    elsif old.Value?
      #puts "VALUE #{old.kind}"
      rule = @grammar.rules[old.kind + "Expression"]
      return @factory.Call(rule)
    end
    return result
  end  

  def ensure_call(pattern, type)
    return pattern if pattern.Call?
    #puts "MAKING CALL:"
    #Print.print(pattern)
    #puts "-"*20
    name = nextName()
    extra = @factory.Rule(name, link(false, pattern.arg, nil, type))
    @grammar.rules << extra
    return @factory.Call(extra)
  end
  
  def makeTemplate(nonterminal_name, klass_name, sep)
    sub_factory = Factory.new(Loader.load("grammar.schema"))
    extension = Loader.load_text 'grammar', sub_factory, <<-GRAMMAR
      start #{nonterminal_name}
      #{nonterminal_name}Alt ::= [#{klass_name}Alt] alts:{#{nonterminal_name}Cond "|"}+
  
      #{nonterminal_name}Cond ::= [#{klass_name}Cond] "[" name:Expression "]" arg:#{nonterminal_name}Sequence
                    | #{nonterminal_name}Sequence
  
     #{nonterminal_name}Sequence ::= [#{klass_name}Seq] elements:{#{nonterminal_name}Field \"#{sep}\"}*
                    | #{nonterminal_name}Field
  
     #{nonterminal_name}Field ::= [#{klass_name}Field] "$" name:sym ":" arg:#{nonterminal_name}
                    | "(" #{nonterminal_name}Alt ")"
                    | #{nonterminal_name}
     #{nonterminal_name} ::=
     Expression ::=
    GRAMMAR
    CopyInto(@factory, extension, @grammar)
    return @grammar.rules["#{nonterminal_name}Alt"]
  end

  def nextName()
    @rule_number += 1
    return "Extra#{@rule_number}"
  end
  
end

