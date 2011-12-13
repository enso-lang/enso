
require 'core/schema/code/factory'

require 'core/grammar/parse/unparse'
require 'core/grammar/parse/to-path'
require 'core/system/utils/location'

class Build
  def self.build(sppf, factory, origins)
    Build.new(factory, origins).build(sppf)
  end

  def initialize(factory, origins)
    @factory = factory
    @origins = origins
  end

  def build(sppf)
    recurse(sppf, nil, accu = {}, nil, fixes = [], paths = {})
    obj = accu.values.first
    fixup(obj, fixes)
    return obj
  end

  def recurse(sppf, owner, accu, field, fixes, paths)
    type = sppf.type 
    sym = type.schema_class.name
    if respond_to?(sym)
      send(sym, type, sppf, owner, accu, field, fixes, paths)
    else
      kids(sppf, owner, accu, nil, fixes, paths)
    end
  end

  def kids(sppf, owner, accu, field, fixes, paths)
    amb_error(sppf) if sppf.kids.length > 1
    return if sppf.kids.empty?
    pack = sppf.kids.first
    recurse(pack.left, owner, accu, field, fixes, paths) if pack.left
    recurse(pack.right, owner, accu, field, fixes, paths)
  end


  def Create(this, sppf, owner, accu, field, fixes, paths)
    current = @factory[this.name]
    kids(sppf, current, {}, nil, fixes, {})
    current._origin = org = origin(sppf)
    accu[org] = current
  end

  def Field(this, sppf, owner, accu, _, fixes, paths)
    field = owner.schema_class.fields[this.name]
    kids(sppf, owner, accu = {}, field, fixes, paths = {})
    accu.each do |org, value|
      update(owner, field, convert(value, field.type))
      update_origin(owner, field, org)
    end
    paths.each do |org, path|
      fixes << Fix.new(path, owner, field, org)
    end
  end

  def Lit(this, sppf, owner, accu, field, fixes, paths)
    return unless field
    accu[origin(sppf)] = sppf.value
  end

  def Value(this, sppf, owner, accu, field, fixes, paths)
    accu[origin(sppf)] = sppf.value
  end

  def Ref(this, sppf, owner, accu, field, fixes, paths)
    paths[origin(sppf)] = ToPath.to_path(this.path, sppf.value)
  end

  def Code(this, sppf, owner, accu, field, fixes, paths)
    owner.instance_eval(this.code.gsub(/@/, 'self.'))
  end

  private

  def amb_error(sppf)
    Unparse.unparse(sppf, s = '')
    raise "Ambiguity: >>>#{s}<<<" 
  end
  
  def origin(sppf)
    path = @origins.path
    offset = @origins.offset(sppf.starts)
    length = sppf.ends - sppf.starts
    start_line = @origins.line(sppf.starts)
    start_column = @origins.column(sppf.starts)
    end_line = @origins.line(sppf.ends)
    end_column = @origins.column(sppf.ends)
    Location.new(path, offset, length, start_line, 
                 start_column, end_line, end_column)
  end

  def convert(value, type)
    return value unless type.Primitive?
    case type.name
    when "str" then value
    when "bool" then value == "true"
    when "int" then value.to_i
    when "real" then value.to_f
    when "sym" then value
    when "atom" then value # ???
    else
      raise "Don't know kind #{type}"
    end
  end


  def fixup(obj, fixes)
    fixes.each do |fix|
      actual = fix.path.deref(obj, fix.obj)
      raise "Could not deref path: #{fix.path}" if actual.nil?
      update(fix.obj, fix.field, actual)
      update_origin(fix.obj, fix.field, fix.origin)
    end
  end

  def update(owner, field, x)
    if field.many then
      owner[field.name] << x
    else
      owner[field.name] = x
    end
  end
  
  def update_origin(owner, field, org)
    return if field.many # no origins for collections
    
    # _origin_of is a OpenStruct (it does not have [])
    # so we use send here. This seems ok, since this
    # is the only place where we will (?) need generic
    # access.
    owner._origin_of.send("#{field.name}=", org)
  end

  class Fix
    attr_reader :path, :obj, :field, :origin
    def initialize(path, obj, field, origin)
      @path = path
      @obj = obj
      @field = field
      @origin = origin
    end    
  end
end
