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
    @root = @factory[schema.root]
  end

  def r2o_start(resultset, query)
    resultset.getIteration(query.classname).each do |x|
      r2o(x, query, query.classname)
    end
    @root
  end

  def r2o(resultset, query, prefix)
    #get key first to check if object already exists
    keyfield = ClassKey(@factory.schema.types[query.classname])
    key = resultset.get(prefix+"_"+keyfield.name)
    obj = make_obj(query.classname, key)
    query.fields.each do |f|
      pname = prefix+"_"+f.name
      if f.query.nil?
        #primitive fields
        obj[f.name] = resultset.get(pname)
      elsif
        if !obj.schema_class.fields[f.name].many
          #non-primitive field (single)
          obj[f.name] = r2o(resultset, f.query, pname)
        else
          #non-primitive field (many)
          resultset.getIteration(pname).each do |x|
            obj[f.name] << r2o(x, f.query, pname)
          end
        end
      end
    end
    obj
  end

  def make_obj(classname, key)
    tablename = tablename_from_name(@schema.root_class, classname)
    if @root[tablename][key].nil?
      obj = @factory[classname]
      obj[ClassKey(obj.schema_class).name] = key
      @root[tablename] << obj
    else
      @root[tablename][key]
    end
  end

end
