
require 'core/system/load/load'
require 'core/schema/tools/copy'

class TemplatizeGrammar < Copy

  def link(traversal, old, field, klass)
    if old.Regular?
      field = klass.all_fields[name]
      type = field.type
      puts "FIELD #{name}"
      if field.traversal  
        if old.many
          # make the grammar rules
          # change foos:{Foo Sep}* ==> foos:([FooSeq] items: {FooAlt Sep}*)
          return @factory.Create(type.name + "Seq", 
            @factory.Field("items",
              super(old, klass)))
          return @grammar.rules("#{name}Sequence")
        else
          # change foo:Foo  ==> foos:FooAlt
          # change foo:(... Foo...)  ==> foos:NewAlt
              where templatize(New ::= ... Foo...)
        end
      end
      klass = type
    end
    super(old, klass)
  end  
  
  def makeTemplate(name, sep)
    extension = Parser.parse(<<GRAMMAR-PART, Loader.load('grammar.grammar'))
      #{name}Alt ::= [#{name}Alt] alts:{#{name}Cond "|"}+
  
      #{name}Cond ::= [#{name}Cond] "[" name:sym "]" arg:#{name}Sequence
                    | #{name}Sequence
  
     #{name}Sequence ::= [#{name}Seq] "(" elements:{#{name}Field \"#{sep}\"}* ")"
                    | #{name}Field
  
     #{name}Field ::= [#{name}Field] name:sym ":" arg:#{name}
                    | #{name}
     #{name} ::=
    GRAMMAR-PART

    @grammar = Union(@grammar, extension)
  end
end


if __FILE__ == $0 then
  require 'core/system/boot/schema_schema'
  require 'core/schema/tools/print'
  require 'core/schema/tools/copy'
  require 'core/schema/code/factory'

  gs = Loader.load("grammar.schema")
  ss = Loader.load("schema.schema")
  sg = Loader.load("schema.grammar")
  G = TemplatizeGrammar.new(Factory.new(gs)).copy(sg)
  
end

