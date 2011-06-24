


require 'core/system/load/load'
require 'core/grammar/code/layout'
require 'core/attributes/code/eval-attr'

include AttributeSchema

def repmin
  attr_schema = Loader.load('repmin.attr-schema')
  src = Loader.load('example.repmin')

  repmin = EvalAttr.eval(attr_schema, src, 'repmin')

  repmin_grammar = Loader.load('repmin.grammar')
  DisplayFormat.print(repmin_grammar, repmin)
  
end


def schema2graph
  attr_schema = Loader.load('schema-graph.attr-schema')
  src_schema = Loader.load('schema.schema')
  trg_schema = Loader.load('graph.schema')
  src = Loader.load('schema.schema')
  schema_graph = EvalAttr.eval(attr_schema, src, 'graph', 
                               Factory.new(trg_schema))

  graph_grammar = Loader.load('graph.grammar')
  DisplayFormat.print(graph_grammar, schema_graph)
end

def graph_basics
  attr_schema = Loader.load('graph.attr-schema')
  src_schema = Loader.load('pointer.schema')
  src = Loader.load('example.pointer')

  pointer_grammar = Loader.load('pointer.grammar')
  DisplayFormat.print(pointer_grammar, src)

  result = EvalAttr.eval(attr_schema, src, 'add')
  Print.print(result)

  result = EvalAttr.eval(attr_schema, src, 'globmin')
  Print.print(result)


  result = EvalAttr.eval(attr_schema, src, 'odds')
  DisplayFormat.print(pointer_grammar, result)

  result = EvalAttr.eval(attr_schema, src, 'trc')
  DisplayFormat.print(pointer_grammar, result)

  result = EvalAttr.eval(attr_schema, src, 'mul2')
  DisplayFormat.print(pointer_grammar, result)

end

def schema_examples
  attr_schema = Loader.load('inheritance.attr-schema')
  src_schema = Loader.load('schema.schema')
  trg_schema = Loader.load('schema.schema')
  src = Loader.load('schema.schema')
  
  schema_grammar = Loader.load('schema.grammar')
  DisplayFormat.print(schema_grammar, src)

  result = EvalAttr.eval(attr_schema, src, 'remove_inheritance')
  DisplayFormat.print(schema_grammar, result)

end

def family2persons
  attr_schema = Loader.load('family2persons.attr-schema')
  src_schema = Loader.load('families.schema')
  trg_schema = Loader.load('persons.schema')
  factory = Factory.new(union(src_schema, trg_schema))
  src = Loader.load('example.families')
  src = Copy.new(factory).copy(src)
  result = EvalAttr.eval(attr_schema, src, 'persons')

  Print.print(result)
end


if __FILE__ == $0 then
  family2persons
  repmin
  graph_basics
  schema_examples
  #schema2graph  #diverges because edges do not have a (composite) key
end
