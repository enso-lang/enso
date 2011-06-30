=begin

Create a structure of objects from a result set

=end

class Result2Object

  def self.result2object(resultset, query, schema)
    Result2Object.new(schema).r2o(resultset, query)
  end

  def initialize(schema)
    @schema = schema
    @factory = Factory.new(schema)
  end

  def r2o(resultset, query)
    root = @factory[query.classname]
    query.fields.each do |f|
      if f.query.nil?
        #primitive field
        root[f.name] = resultset.get(f.name)
      elsif
        #non-primitive field (single)
        #non-primitive field (many)
        result_j.getIteration(f.name).each do |x|
          list_j << "name=#{x.getString("root_CompanyName")}"
          root[f.name] << r2o(resultset, query)
        end
      end
    end
    return root
  end

  def name_from_tablename(tblname)
    tblname[0..-1]
  end
end

result_t.getIteration("root").each do |x|
  puts "Supplier=#{x.getString("CompanyName")}"
  x.getIteration("Products").each do |y|
    puts "  - Product: #{y.getString("ProductName")}"
  end
end
