
class Database
  def initialize
    @tables = []
  end
  
  def table(tbl)
    @tables << tbl
  end

  def render(out = '')
    @tables.each do |tbl|
      tbl.render(out)
    end
    return out
  end
end


class Table 
  attr_reader :name

  def initialize(name)
    @name = name
    @columns = {}
    @foreign_keys = {}
  end

  def column(name, type)
    @columns[name] = type
  end

  def foreign_key(name, type)
    @foreign_keys[name] = type
  end

  def not_null(name)
    puts "Not null: #{name}"
  end

  def unique(name)
    puts "unique: #{name}"
  end

  def render(out = '')
    out << "create table #{name} (\n"
    out << "\tinteger id primary key autoincrement\n"
    @columns.each do |n, t|
      out << "\t#{t.type} #{n}\n"
    end
    @foreign_keys.each do |n, t|
      out << "\tinteger #{n} references #{t.name}\n"
    end
    out << ")\n"
  end
end


class Scalar
  def initialize(name)
    @name = name
  end

  def type
    case @name 
    when 'str' then return 'string'
    when 'int' then return 'integer'
    when 'bool' then return 'boolean'
    else
      raise "Unsupported primitive: #{@name}"
    end
  end
end


class Schema2SQL 
  def self.to_sql(schema) 
    self.new.eval(schema)
  end

  def initialize
    @memo = {}
  end

  def eval(this, *args)
    if @memo[this] then
      return @memo[this]
    end
    @this = this
    send(this.schema_class.name, this, *args)
  end

  def with(obj)
    @memo[@this] = obj
    yield obj
    return obj
  end

  def Schema(this)
    db = Database.new
    this.classes.each do |c|
      db.table(eval(c))
    end
    return db
  end
  
  def Klass(this)
    with(Table.new(this.name)) do |tbl|
      this.fields.each do |f|
        eval(f)
      end
      this.supers.each do |c|
        tbl.foreign_key(c.name, eval(c));
      end
    end
  end
  
  def Field(this)
    tbl = eval(this.owner)
    if !this.many then
      if this.type.Primitive? then
        tbl.column(this.name, eval(this.type))
      else
        tbl.foreign_key(this.name, eval(this.type))
      end
      if !this.optional then
        tbl.not_null(this.name)
      end
    elsif this.many && this.inverse then
      eval(this.type).foreign_key(this.inverse.name, tbl)
    end
    if this.key then
      tbl.unique(this.name)
    end
  end

  def Primitive(this)
    Scalar.new(this.name)
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'

  ss = Loader.load('schema.schema')

  puts Schema2SQL.to_sql(ss).render
  

end
