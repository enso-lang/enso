require 'core/schema/tools/copy'

def rename_schema!(schema, map)
  #rename all the classes
  map.each do |from,to|
    x = schema.types[from]
    schema.types[from] = nil
    x.name = to
    schema.types << x
  end

  schema
end

def rename_schema(schema, map)
  rename_schema!(Clone(schema), map)
end

def rename_grammar!(grammar, map)
  #rename all rules

  #rename creates
end

def rename_grammar(grammar, map)
  rename_schema!(Clone(grammar), map)
end
