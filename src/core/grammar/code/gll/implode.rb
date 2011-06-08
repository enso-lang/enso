
require 'core/system/boot/instance_schema'
require 'core/schema/code/factory'

require 'core/grammar/code/gll/unparse'

class Implode

  def self.implode(sppf, origins)
    Implode.new(origins).implode(sppf)
  end
  
  def initialize(origins)
    @origins = origins
    @if = Factory.new(InstanceSchema.schema)
  end

  def origin(sppf)
    loc = @if.Location
    loc.path = @origins.path
    loc.offset = sppf.starts
    loc.length = sppf.ends - sppf.starts
    loc.start_line = @origins.line(sppf.starts)
    loc.start_column = @origins.column(sppf.starts)
    loc.end_line = @origins.line(sppf.ends)
    loc.end_column = @origins.column(sppf.ends)
    return loc
  end

  def implode(sppf)
    insts = @if.Instances
    recurse(sppf, insts.instances, false)
    return insts
  end
  
  def recurse(sppf, accu, in_field)
    type = sppf.type 
    sym = type.schema_class.name
    if respond_to?(sym)
      send(sym, type, sppf, accu, in_field)
    else
      kids(sppf, accu, false)
    end
  end

  def kids(sppf, accu, in_field)
    if sppf.kids.length > 1 then
      s = ''
      Unparse.unparse(sppf, s)
      puts "\t #{s}"
      raise "Ambiguity!" 
    end
    
    return if sppf.kids.empty?
    pack = sppf.kids.first
    recurse(pack.left, accu, in_field) if pack.left
    recurse(pack.right, accu, in_field)
  end

  def Create(this, sppf, accu, in_field)
    #puts "Creating: #{this.name}"
    inst = @if.Instance(origin(sppf), this.name)
    kids(sppf, inst.contents, false)
    accu << inst
  end

  def Field(this, sppf, accu, in_field)
    fld = @if.Field(this.name)
    kids(sppf, fld.values, true)
    accu << fld
  end

  def Lit(this, sppf, accu, in_field)
    return unless in_field
    accu << @if.Prim(origin(sppf), 'str', this.value)
  end

  def Value(this, sppf, accu, in_field)
    accu << @if.Prim(origin(sppf), this.kind, sppf.value)
  end

  def Ref(this, sppf, accu, in_field)
    accu << @if.Ref(origin(sppf), sppf.value)
  end

  def Code(this, sppf, accu, in_field)
    accu << @if.Code(sppf.value)
  end

end
