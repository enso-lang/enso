=begin

Create a structure of objects from a result set

=end

require 'core/schema/code/factory'
require 'core/batches/code/utils'

class Result2Object

  def self.result2object(resultset, query, schema)
    Result2Object.new(schema).r2o_start(resultset, query)
  end

  def initialize(schema)
    @schema = schema
    @factory = Factory.new(schema)
    @root = @factory['Northwind']
  end

  def r2o_start(resultset, query)
    resultset.getIteration(query.classname).each do |x|
      @root[tablename_from_name(query.classname)] << r2o(x, query)
    end
    return @root
  end

  def r2o(resultset, query)
    root = @factory[query.classname]
    query.fields.each do |f|
      if f.query.nil?
        #primitive fields
        root[f.name] = resultset.get(f.name)
      elsif
        if !root.schema_class.fields[f.name].many
          #non-primitive field (single)
          root[f.name] = r2o(resultset.get(f.name), f.query)
        else
          #non-primitive field (many)
          resultset.getIteration(f.name).each do |x|
            root[f.name] << r2o(x, f.query)
          end
        end
      end
    end
    return root
  end

end
