
require 'core/schema/code/factory'

require 'core/grammar/parse/unparse'
require 'core/grammar/parse/to-path'
require 'core/system/utils/location'

# TODO: pos is never used....
# We never have non-keyed collections of cross links

class Build
  def self.build(sppf, factory, origins)
    build = Build.new(factory, origins)
    build.recurse(sppf, nil, accu = [], nil, 0, fixes = [], paths = [])
    obj = accu.first
    #puts obj
    fixes.each do |fix|
      fix.apply(obj)
    end
    return obj
  end
  
  attr_reader :root
  def initialize(factory, origins)
    @factory = factory
    @origins = origins
  end

  def recurse(sppf, owner, accu, field, pos, fixes, paths)
    type = sppf.type 
    sym = type.schema_class.name
    if respond_to?(sym)
      send(sym, type, sppf, owner, accu, field, pos, fixes, paths)
    else
      kids(sppf, owner, accu, nil, pos, fixes, paths)
    end
  end

  def kids(sppf, owner, accu, field, pos, fixes, paths)
    if sppf.kids.length > 1 then
      Unparse.unparse(sppf, s = '')
      #puts "\t #{s}"
      raise "Ambiguity!" 
    end
    
    return if sppf.kids.empty?
    pack = sppf.kids.first
    recurse(pack.left, owner, accu, field, pos, fixes, paths) if pack.left
    recurse(pack.right, owner, accu, field, pos, fixes, paths)
  end



  def Create(this, sppf, owner, accu, field, pos, fixes, paths)
    current = @factory[this.name]
    kids(sppf, current, [], nil, 0, fixes, paths)
    current._origin = origin(sppf)
    if field && owner then
      update(owner, field, pos, current)
      update_origin(owner, field, current._origin)
    else
      accu << current
    end
  end

  def Field(this, sppf, owner, accu, _, pos, fixes, paths)
    field = owner.schema_class.fields[this.name]
    #puts "FIELD: #{this.name} --> #{field}"
    kids(sppf, owner, accu = [], field, 0, fixes, paths = [])
    accu.each do |v|
      #puts "Updating: #{owner}.#{field.name}: #{v}"
      update(owner, field, pos, v)
    end
    paths.each do |path|
      fixes << Fix.new(path, owner, field, pos)
    end
  end

  def Lit(this, sppf, owner, accu, field, pos, fixes, paths)
    return unless field
    accu << sppf.value
    #update(owner, field, pos, sppf.value)
    #update_origin(owner, field, origin(sppf))
    #return owner
  end

  def Value(this, sppf, owner, accu, field, pos, fixes, paths)
    return unless field
    accu << convert_typed(sppf.value, this.kind, field.type)
    #update(owner, field, pos, convert_typed(sppf.value, this.kind, field.type))
    #update_origin(owner, field, origin(sppf))
    #return owner
  end

  def Ref(this, sppf, owner, accu, field, pos, fixes, paths)
    #puts "REF: #{sppf.value}: #{ToPath.to_path(this.path, sppf.value)}"
    paths << ToPath.to_path(this.path, sppf.value)
    # TODO: do something with pos.

    #if field.many && !ClassKey(field.type) then
    #  accu << nil
    #  #update(owner, field, pos, nil)
    #end
    #update_origin(owner, field, origin(sppf))
    #return owner
  end

  def Code(this, sppf, owner, accu, field, pos, fixes, paths)
    owner.instance_eval(this.code.gsub(/@/, 'self.'))
  end

  private
  
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

  def update(owner, field, pos, x)
    return pos if field.nil?
    if field.many then
      owner[field.name] << x
      return pos + 1
    else
      owner[field.name] = x
    end
    return pos
  end
  
  def update_origin(owner, field, org)
    return if field.nil?
    
    # currently, no support for many fields:
    # since we allow lists of refs, the origin table
    # then would have to mimick the fixup process
    # (primitives are not allowed in many fields anyhow)
    return if field.many
    
    # _origin_of is a OpenStruct (it does not have [])
    # so we use send here. This seems ok, since this
    # is the only place where we will (?) need generic
    # access.
    owner._origin_of.send("#{field.name}=", org)
  end

  def convert_typed(value, type, ftype = nil)
    case type
    when "str" then value
    when "bool" then value == "true"
    when "int" then value.to_i
    when "real" then value.to_f
    when "sym" then value
    when "atom" then ftype.nil? ? value : convert_typed(value, ftype.name)
    else
      raise "Don't know kind #{type}"
    end
  end

  class Fix
    def initialize(path, this, field, pos)
      @path = path
      @this = this
      @field = field
      @pos = pos
    end
    
    def apply(root)
      # nil for parent; unsupported yet
      # (and static checking of parent paths is problematic)
      #puts "Dereffing: #{@path}"
      actual = @path.deref(root, @this)
      raise "Could not deref path: #{@path}" if actual.nil?
      if @field.many
        if ClassKey(@field.type)
          @this[@field.name] << actual
        else
          @this[@field.name][@pos] = actual
        end
      else
        @this[@field.name] = actual
      end
    end
  end
end
