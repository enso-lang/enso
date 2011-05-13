require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/schema/code/factory'

point_schema = Loader.load('point.schema')
point_grammar = Loader.load('point.grammar')

p1 = Loader.load('diff-test1.point')
DisplayFormat.print(point_grammar, p1)

p2 = Loader.load('diff-test2.point')
DisplayFormat.print(point_grammar, p2)

# diff construction functions

def delta (old)
  #delta creates a 'delta' version of a schema to store diff results

  factory = Factory.new(SchemaSchema.schema)
  schema = factory.Schema()

  old.types.each do |t| Type(t) end
  schema.finalize
  return schema
end

def Type (old) 
  # there is no need to do any memoization because our fixed schema-schema  
  #does not have cyclically defined inner types (no sane language has)
  new = self.send(old.schema_class.name, old)
  
end


def transform ()
  #transformations and edit operations
end

# differencing functions

def diff (o1, o2)
  #result of a diff is a graph that conforms to specified schema
  # nodes and edges in the graph are the union of the nodes in both instances
  # furthermore, every node is marked with a delta type: A(dded), D(eleted), M(odified)
  # every attribute (which includes edges) is marked with both old and new values

  Line res;
  
end

def match (o1, o2)
  #result of a match is a set of pairs of classes conforming to the specified schema
  # each pair of classes is a match between 
  # classes are refered to by their paths
end

DisplayFormat.print(Loader.load('schema.grammar'), point_schema)

deltaCons = DeltaTransform.new().Schema(point_schema)

DisplayFormat.print(Loader.load('deltaschema.grammar'), deltaCons)
#DisplayFormat.print(Loader.load('deltaschema.grammar'), deltaCons)
