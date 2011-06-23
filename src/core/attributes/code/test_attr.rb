


require 'core/system/load/load'
require 'core/grammar/code/layout'
require 'core/attributes/code/eval-attr'

include AttributeSchema

def repmin
  attr_schema = Loader.load('repmin.attr-schema')
  src_schema = Loader.load('repmin.schema')
  src = Loader.load('example.repmin')

  repmin = EvalAttr.eval_attr_schema(attr_schema, src, 'repmin',
                                     src_schema)

  repmin_grammar = Loader.load('repmin.grammar')
  DisplayFormat.print(repmin_grammar, repmin)
  
end


def schema2graph
  attr_schema = Loader.load('schema-graph.attr-schema')
  src_schema = Loader.load('schema.schema')
  trg_schema = Loader.load('graph.schema')
  src = Loader.load('schema.schema')
  schema_graph = EvalAttr.eval_attr_schema(attr_schema, src, 'graph', 
                                           src_schema, trg_schema)

  graph_grammar = Loader.load('graph.grammar')
  DisplayFormat.print(graph_grammar, schema_graph)
end

def graph_basics
  attr_schema = Loader.load('graph.attr-schema')
  src_schema = Loader.load('pointer.schema')
  src = Loader.load('example.pointer')

  pointer_grammar = Loader.load('pointer.grammar')
  DisplayFormat.print(pointer_grammar, src)

  #result = EvalAttr.eval_attr_schema(attr_schema, src, 'add', src_schema)
  #Print.print(result)
  result = EvalAttr.eval_attr_schema(attr_schema, src, 'globmin', src_schema)
  Print.print(result)


  result = EvalAttr.eval_attr_schema(attr_schema, src, 'odds', src_schema)
  DisplayFormat.print(pointer_grammar, result)

end


if __FILE__ == $0 then
  graph_basics
  repmin
  schema2graph
end
