=begin

Create a structure of objects from a result set

=end

require 'core/schema/code/factory'
require 'apps/batches/code/utils'
require 'apps/batches/code/secureschema'

class Result2Object

  def self.result2object(resultset, query, schema)
    Result2Object.new(schema).r2o_start(resultset, query)
  end

  def initialize(schema)
    @schema = SecureSchema.secure_transform!(Clone(schema))
    puts "Schema is: "
    Print::Print.print(@schema)
    @factory = Factory::new(@schema)
    @root = @factory[@schema.root]
  end

  def r2o_start(resultset, query)
    resultset.getIteration(query.classname).each do |x|
      r2o(x, query, query.classname)
    end
    @root
  end

  private

  def r2o(resultset, query, prefix)
    #get key first to check if object already exists
    keyfield = @factory.schema.types[query.classname].key
    key = resultset.get(prefix+"_"+keyfield.name)
    obj = make_obj(query.classname, key)
    query.fields.each do |f|
      pname = prefix+"_"+f.name
      if f.query.nil?
        #primitive fields
        obj[f.name] = coerce(resultset.get(pname), obj.schema_class.fields[f.name].type)
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
    Print::Print.print(obj)
    obj
  end

  def make_obj(classname, key)
    tablename = tablename_from_name(@schema.root_class, classname)
    if @root[tablename][key].nil?
      obj = @factory[classname]
      obj[obj.schema_class).key.name] = key
      @root[tablename] << obj
    else
      @root[tablename][key]
    end
  end

  def coerce(val, type)
    if val.is_a? Integer and type.name == "bool"
      val!=0
    else
      val
    end
  end

end
