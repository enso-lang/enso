
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
    @constraints = {}
    @cascades = {}
    @spine_triggers = {}
  end

  def column(name, type)
    @columns[name] = type
  end

  def spine_trigger(name, kid, kid_col)
    @spine_triggers[name] = [kid, kid_col]
  end

  def render_triggers(out = '')
    @spine_triggers.each do |parent_col, pair|
      kid = pair[0]
      kid_col = pair[1]
      out << "create trigger delete_#{parent_col}\n"
      out << "\tbefore delete on #{table_name} for each row\n"
      out << "\tbegin delete from #{kid.table_name} where\n"
      out << "\t\t#{kid.table_name}.#{kid_col} = old.#{id_col};\n"
      out << "\tend;\n"
    end
  end

  def foreign_key(name, type)
    @foreign_keys[name] = type
  end

  def cascade(name)
    @cascades[name] = "on delete cascade"
  end

  def not_null(name)
    add_constraint(name, "not null")
  end

  def unique(name)
    add_constraint(name, "unique")
  end

  def default(name, value)
    add_constraint(name, "default '#{value}'")
  end

  def add_constraint(name, cons)
    @constraints[name] ||= []
    @constraints[name] << cons
  end
    

  def table_name
    # "#{name}_table"
    name
  end
  
  def id_col
    return '_id'
  end
  
  def render(out = '')
    out << "create table #{table_name} (\n"
    cols = ["\t#{id_col} integer primary key autoincrement"]
    cols += @columns.map do |n, t|
      col = "\t#{n} #{t.type}"
      if @constraints[n] then
        col << ' ' + @constraints[n].join(' ')
      end
      col
    end
    cols += @foreign_keys.map do |n, t|
      col = "\t#{n} integer references #{t.table_name} (#{id_col})"
      if @cascades[n] then
        col << " #{@cascades[n]}"
      end
      col
    end
    out << cols.join(",\n") + "\n);\n"
    render_triggers(out)
  end
end


class Scalar
  def initialize(name)
    @name = name
  end

  def type
    case @name 
    when 'str' then 'string'
    when 'int' then 'integer'
    when 'real' then 'real'
    when 'bool' then 'boolean'
    else
      raise "Unsupported primitive: #{@name}"
    end
  end

  def default
    case @name 
    when 'str' then ''
    when 'int' then 0
    when 'real' then 0.0
    when 'bool' then false
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

  def super_column(name)
    "#{name}_super"
  end

  def Schema(this)
    db = Database.new
    this.classes.each do |c|
      db.table(eval(c))
    end
    return db
  end
  
  def Class(this)
    with(Table.new(this.name)) do |tbl|
      this.defined_fields.each do |f|
        eval(f)
      end
      this.supers.each do |c|
        tbl.foreign_key(super_column(c.name), eval(c))
        tbl.cascade(super_column(c.name))
      end
      this.subclasses.each do |c|
       tbl.spine_trigger(super_column(c.name), eval(c), super_column(this.name))
      end
    end
  end
  
  def Field(this)
    return if this.computed
    tbl = eval(this.owner)
    if !this.many then
      if this.type.Primitive? then
        pt = eval(this.type)
        tbl.column(this.name, pt)
        tbl.default(this.name, pt.default)
      else
        tbl.foreign_key(this.name, eval(this.type))
        if this.traversal then
          tbl.cascade(this.name)
        end
      end
      if !this.optional then
        tbl.not_null(this.name)
      end
    elsif this.many && this.inverse then
      target = eval(this.type)
      target.foreign_key(this.inverse.name, tbl)
      tbl.spine_trigger(this.name, target, this.inverse.name)
    elsif this.many then
      puts "Warning: no inverse on many field  #{this.name}"
      target = eval(this.type)
      inv = "#{this.name}_inverse"
      target.foreign_key(inv, tbl)
      tbl.spine_trigger(this.name, target, inv)
    end
    if this.key then
      tbl.unique(this.name)
    end
  end

  def Primitive(this)
    Scalar.new(this.name)
  end
end


require 'core/system/load/load'

ss = Load::load('schema.schema')
puts Schema2SQL.to_sql(ss).render

#gs = Load::load('grammar.schema')
#puts Schema2SQL.to_sql(gs).render
  
